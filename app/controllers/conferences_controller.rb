require 'geocoder/calculations'
require 'rest_client'

class ConferencesController < ApplicationController
	include ScheduleHelper

	before_action :set_conference, only: [:show, :edit, :update, :destroy, :registrations]
	before_filter :authenticate, only: [:registrations]

	def authenticate
		auth = get_secure_info(:registrations_access)
		authenticate_or_request_with_http_basic('Administration') do |username, password|
			username == auth[:username] && password == auth[:password]
		end
	end

	def register
		set_conference

		@register_template = nil

		if logged_in?
			set_or_create_conference_registration

			@name = current_user.firstname
			# we should phase out last names
			@name += " #{current_user.lastname}" if current_user.lastname

			@name ||= current_user.username

			@is_host = @this_conference.host? current_user
		else
			@register_template = :confirm_email
		end

		steps = nil
		return do_404 unless registration_steps.present?
		
		@register_template = :administration if params[:admin_step].present?

		@errors = {}
		@warnings = []
		form_step = params[:button] ? params[:button].to_sym : nil

		# process any data that was passed to us
		if form_step
			if form_step.to_s =~ /^prev_(.+)$/
				steps = registration_steps
				@register_template = steps[steps.find_index($1.to_sym) - 1]
			elsif form_step == :paypal_confirm
				if @registration.present? && @registration.payment_confirmation_token == params[:confirmation_token]
					@amount = PayPal!.details(params[:token]).amount.total
					@registration.payment_info = {:payer_id => params[:PayerID], :token => params[:token], :amount => @amount}.to_yaml

					@amount = (@amount * 100).to_i.to_s.gsub(/^(.*)(\d\d)$/, '\1.\2')

					@registration.save!
				end

				@page_title = 'articles.conference_registration.headings.Payment'
				@register_template = :paypal_confirm
			elsif form_step == :paypal_confirmed
				info = YAML.load(@registration.payment_info)
				@amount = nil
				status = nil
				if ENV['RAILS_ENV'] == 'test'
					status = info[:status]
					@amount = info[:amount]
				else
					paypal = PayPal!.checkout!(info[:token], info[:payer_id], PayPalRequest(info[:amount]))
					status = paypal.payment_info.first.payment_status
					@amount = paypal.payment_info.first.amount.total
				end
				if status == 'Completed'
					@registration.registration_fees_paid ||= 0
					@registration.registration_fees_paid += @amount

					# don't complete the step unless fees have been paid
					if @registration.registration_fees_paid > 0
						@registration.steps_completed << :payment
						@registration.steps_completed.uniq!
					end

					@registration.save!
				else
					@errors = :incomplete
					@register_template = :payment
				end
				@page_title = 'articles.conference_registration.headings.Payment'
			else

				case form_step
				when :confirm_email
					return do_confirm
				when :contact_info
					if params[:name].present? && params[:name].gsub(/[\s\W]/, '').present?
						current_user.firstname = params[:name].squish
						current_user.lastname = nil
					else
						@errors[:name] = :empty
					end

					if params[:location].present? && params[:location].gsub(/[\s\W]/, '').present? && (l = Geocoder.search(params[:location], language: 'en')).present?
						corrected = view_context.location(l.first, @this_conference.locale)

						if corrected.present?
							@registration.city = corrected
							if params[:location].gsub(/[\s,]/, '').downcase != @registration.city.gsub(/[\s,]/, '').downcase
								@warnings << view_context._('warnings.messages.location_corrected', vars: {original: params[:location], corrected: corrected})
							end
						else
							@errors[:location] = :unknown
						end
					else
						@errors[:location] = :empty
					end

					if params[:languages].present?
						current_user.languages = params[:languages].keys
					else
						@errors[:languages] = :empty
					end

					current_user.save! unless @errors.present?
				when :hosting
					@registration.can_provide_housing = params[:can_provide_housing].present?
					if params[:not_attending]
						@registration.is_attending = 'n'

						if current_user.is_subscribed.nil?
							current_user.is_subscribed = false
							current_user.save!
						end
					else
						@registration.is_attending = 'y'
					end

					@registration.housing_data = {
						address: params[:address],
						phone: params[:phone],
						space: {
							bed_space: params[:bed_space],
							floor_space: params[:floor_space],
							tent_space: params[:tent_space],
						},
						considerations: (params[:considerations] || {}).keys,
						availability: [ params[:first_day], params[:last_day] ],
						notes: params[:notes]
					}
				when :questions
					# create the companion's user account and send a registration link unless they have already registered
					generate_confirmation(User.create(email: params[:companion]), register_path(@this_conference.slug)) if params[:companion].present? && User.find_by_email(params[:companion]).nil?
					
					@registration.housing = params[:housing]
					@registration.arrival = params[:arrival]
					@registration.departure = params[:departure]
					@registration.housing_data = {
						companions: [ params[:companion] ]
					}
					@registration.bike = params[:bike]
					@registration.food = params[:food]
					@registration.allergies = params[:allergies]
					@registration.other = params[:other]
				when :payment
					amount = params[:amount].to_f

					if amount > 0
						@registration.payment_confirmation_token = ENV['RAILS_ENV'] == 'test' ? 'token' : Digest::SHA256.hexdigest(rand(Time.now.to_f * 1000000).to_i.to_s)
						@registration.save
						
						host = "#{request.protocol}#{request.host_with_port}"
						response = PayPal!.setup(
							PayPalRequest(amount),
							register_paypal_confirm_url(@this_conference.slug, :paypal_confirm, @registration.payment_confirmation_token),
							register_paypal_confirm_url(@this_conference.slug, :paypal_cancel, @registration.payment_confirmation_token),
							noshipping: true,
							version: 204
						)
						if ENV['RAILS_ENV'] != 'test'
							redirect_to response.redirect_uri
						end
						return
					end
				end

				if @errors.present?
					@register_template = form_step
				else
					unless @registration.nil?
						steps = registration_steps
						step_index = steps.find_index(form_step)
						@register_template = steps[step_index + 1] if step_index.present?

						# have we reached a new level?
						unless @registration.steps_completed.include? form_step.to_s
							# this step is only completed if a payment has been made
							if form_step != :payment || (@registration.registration_fees_paid || 0) > 0
								@registration.steps_completed ||= []
								@registration.steps_completed << form_step
								@registration.steps_completed.uniq!
							end

							# workshops is the last step
							if @register_template == :workshops
								UserMailer.send_mail :registration_confirmation do
									{
										:args => @registration
									}
								end
							end
						end

						@registration.save!
					end
				end
			end
		end

		steps ||= registration_steps

		# make sure we're on a valid step
		@register_template ||= (params[:step] || current_step).to_sym

		if logged_in? && @register_template != :paypal_confirm
			# if we're logged in
			if !steps.include?(@register_template)
				# and we are not viewing a valid step
				return redirect_to register_path(@this_conference.slug)
			elsif @register_template != current_step && !registration_complete? && !@registration.steps_completed.include?(@register_template.to_s)
				# or the step hasn't been reached, registration is not yet complete, and we're not viewing the latest incomplete step
				return redirect_to register_path(@this_conference.slug)
			end
			# then we'll redirect to the current registration step
		end

		# prepare the form
		case @register_template
		when :questions
			# see if someone else has asked to be your companion
			if @registration.housing_data.blank?
				ConferenceRegistration.where(
					conference_id: @this_conference.id, can_provide_housing: [nil, false]
					).where.not(housing_data: nil).each do | r |
					@registration.housing_data = {
							companions: [ r.user.email ]
						} if r.housing_data['companions'].present? && r.housing_data['companions'].include?(current_user.email)
				end
				
				@registration.housing_data ||= { }
			end
			@page_title = 'articles.conference_registration.headings.Registration_Info'
		when :payment
			@page_title = 'articles.conference_registration.headings.Payment'
		when :workshops
			@page_title = 'articles.conference_registration.headings.Workshops'
			
			# initalize our arrays
			@my_workshops = Array.new
			@requested_workshops = Array.new
			@workshops_in_need = Array.new
			@workshops = Array.new

			# put wach workshop into the correct array
			Workshop.where(conference_id: @this_conference.id).each do | workshop |
				if workshop.active_facilitator?(current_user)
					@my_workshops << workshop
				elsif workshop.requested_collaborator?(current_user)
					@requested_workshops << workshop
				elsif workshop.needs_facilitators
					@workshops_in_need << workshop
				else
					@workshops << workshop
				end
			end

			# sort the arrays by name
			@my_workshops.sort! { |a, b| a.title.downcase <=> b.title.downcase }
			@requested_workshops.sort! { |a, b| a.title.downcase <=> b.title.downcase }
			@workshops_in_need.sort! { |a, b| a.title.downcase <=> b.title.downcase }
			@workshops.sort! { |a, b| a.title.downcase <=> b.title.downcase }
		when :contact_info
			@page_title = 'articles.conference_registration.headings.Contact_Info'
		when :hosting
			@page_title = 'articles.conference_registration.headings.Hosting'
			@hosting_data = @registration.housing_data || {}
			@hosting_data['space'] ||= Hash.new
			@hosting_data['availability'] ||= Array.new
			@hosting_data['considerations'] ||= Array.new
		when :policy
			@page_title = 'articles.conference_registration.headings.Policy_Agreement'
		when :administration
			@warnings << flash[:error] if flash[:error].present?
			@admin_step = params[:admin_step] || view_context.admin_steps.first.to_s
			return do_404 unless view_context.valid_admin_steps.include?(@admin_step.to_sym)
			@page_title = 'articles.conference_registration.headings.Administration'

			case @admin_step.to_sym
			when :organizations
				@organizations = Organization.all

				if request.format.xlsx?
					logger.info "Generating organizations.xls"
					@excel_data = {
						columns: [:name, :street_address, :city, :subregion, :country, :postal_code, :email, :phone, :status],
						keys: {
								name: 'forms.labels.generic.name',
								street_address: 'forms.labels.generic.street_address',
								city: 'forms.labels.generic.city',
								subregion: 'forms.labels.generic.subregion',
								country: 'forms.labels.generic.country',
								postal_code: 'forms.labels.generic.postal_code',
								email: 'forms.labels.generic.email',
								phone: 'forms.labels.generic.phone',
								status: 'forms.labels.generic.status'
							},
						data: [],
					}
					@organizations.each do | org |
						if org.present?
							address = org.locations.first
							@excel_data[:data] << {
								name: org.name,
								street_address: address.present? ? address.street : nil,
								city: address.present? ? address.city : nil,
								subregion: address.present? ? I18n.t("geography.subregions.#{address.country}.#{address.territory}") : nil,
								country: address.present? ? I18n.t("geography.countries.#{address.country}") : nil,
								postal_code: address.present? ? address.postal_code : nil,
								email: org.email_address,
								phone: org.phone,
								status: org.status
							}
						end
					end
					return respond_to do | format |
						format.xlsx { render xlsx: :stats, filename: "organizations" }
					end
				end
			when :stats
				@registrations = ConferenceRegistration.where(:conference_id => @this_conference.id).sort { |a,b| (a.user.present? ? (a.user.firstname || '') : '').downcase <=> (b.user.present? ? (b.user.firstname || '') : '').downcase }
				@excel_data = {
					columns: [
							:name,
							:email,
							:status,
							:registration_fees_paid,
							:date,
							:city,
							:preferred_language,
							:languages,
							:arrival,
							:departure,
							:housing,
							:bike,
							:food,
							:companion,
							:companion_email,
							:allergies
						],
					column_types: {
							name: :bold,
							date: :datetime,
							arrival: [:date, :day],
							departure: [:date, :day],
							registration_fees_paid: :money,
							allergies: :text
						},
					keys: {
							name: 'forms.labels.generic.name',
							email: 'forms.labels.generic.email',
							status: 'forms.labels.generic.registration_status',
							city: 'forms.labels.generic.location',
							date: 'articles.conference_registration.terms.Date',
							languages: 'articles.conference_registration.terms.Languages',
							preferred_language: 'articles.conference_registration.terms.Preferred_Languages',
							arrival: 'forms.labels.generic.arrival',
							departure: 'forms.labels.generic.departure',
							housing: 'forms.labels.generic.housing',
							bike: 'forms.labels.generic.bike',
							food: 'forms.labels.generic.food',
							companion: 'articles.conference_registration.terms.companion',
							companion_email: 'forms.labels.generic.email',
							allergies: 'forms.labels.generic.allergies',
							registration_fees_paid: 'articles.conference_registration.headings.fees_paid'
						},
					data: []
				}
				@registrations.each do | r |
					user = r.user_id ? User.where(id: r.user_id).first : nil
					if user.present?
						companion = view_context.companion(r)
						companion = companion.is_a?(User) ? companion.name : (view_context._"articles.conference_registration.terms.registration_status.#{companion}") if companion.present?
						steps = r.steps_completed || []

						@excel_data[:data] << {
							id: r.id,
							name: user.firstname || '',
							email: user.email || '',
							status: (view_context._"articles.conference_registration.terms.registration_status.#{(steps.include? 'questions') ? 'registered' : ((steps.include? 'contact_info') ? 'preregistered' : 'unregistered')}"),
							date: r.created_at ? r.created_at.strftime("%F %T") : '',
							city: r.city || '',
							preferred_language: user.locale.present? ? (view_context.language_name user.locale) : '',
							languages: ((r.languages || []).map { |x| view_context.language_name x }).join(', ').to_s,
							arrival: r.arrival ? r.arrival.strftime("%F %T") : '',
							departure: r.departure ? r.departure.strftime("%F %T") : '',
							housing: r.housing.present? ? (view_context._"articles.conference_registration.questions.housing.#{r.housing}") : '',
							bike: r.bike.present? ? (view_context._"articles.conference_registration.questions.bike.#{r.bike}") : '',
							food: r.food.present? ? (view_context._"articles.conference_registration.questions.food.#{r.food}") : '',
							companion: companion,
							companion_email: ((r.housing_data || {})['companions'] || ['']).first,
							allergies: r.allergies,
							registration_fees_paid: r.registration_fees_paid,
							raw_values: {
								housing: r.housing,
								bike: r.bike,
								food: r.food,
								arrival: r.arrival,
								departure: r.departure
							},
							html_values: {
								date: r.created_at.present? ? r.created_at.strftime("%F %T") : '',
								arrival: r.arrival.present? ? view_context.date(r.arrival.to_date, :span_same_year_date_1) : '',
								departure: r.departure.present? ? view_context.date(r.departure.to_date, :span_same_year_date_1) : ''
							}
						}
					end
				end

				if request.format.xlsx?
					logger.info "Generating stats.xls"
					return respond_to do | format |
						format.xlsx { render xlsx: :stats, filename: "stats-#{DateTime.now.strftime('%Y-%m-%d')}" }
					end
				else
					@registration_count = @registrations.size
					@completed_registrations = 0
					@bikes = 0
					@donation_count = 0
					@donations = 0
					@food = { meat: 0, vegan: 0, vegetarian: 0, all: 0 }
					@column_options = {
						housing: ConferenceRegistration.all_housing_options.map { |h| [
							(view_context._"articles.conference_registration.questions.housing.#{h}"),
							h] },
						bike: ConferenceRegistration.all_bike_options.map { |b| [
							(view_context._"articles.conference_registration.questions.bike.#{b}"),
							b] },
						food: ConferenceRegistration.all_food_options.map { |f| [
							(view_context._"articles.conference_registration.questions.food.#{f}"),
							f] },
						arrival: view_context.conference_days_options_list(:before_plus_one),
						departure: view_context.conference_days_options_list(:after_minus_one),
						preferred_language: I18n.backend.enabled_locales.map { |l| [
								(view_context.language_name l), l
							] }
					}
					@registrations.each do | r |
						if r.steps_completed.include? 'questions'
							@completed_registrations += 1

							@bikes += 1 if r.bike == 'yes'

							@food[r.food.to_sym] += 1
							@food[:all] += 1

							if r.registration_fees_paid.present? && r.registration_fees_paid > 0
								@donation_count += 1
								@donations += r.registration_fees_paid
							end
						end
					end
				end
			when :housing
				# do a full analysis
				analyze_housing
				
				if request.format.xlsx?
					logger.info "Generating housing.xls"
					@excel_data = {
						columns: [:name, :phone, :street_address, :email, :availability, :considerations, :empty, :empty, :empty, :guests],
						keys: {
								name: 'forms.labels.generic.name',
								street_address: 'forms.labels.generic.street_address',
								email: 'forms.labels.generic.email',
								phone: 'forms.labels.generic.phone',
								availability: 'articles.conference_registration.headings.host.availability',
								considerations: 'articles.conference_registration.headings.host.considerations'
							},
						column_types: {
								name: :bold,
								guests: :table
							},
						data: [],
					}
					@hosts.each do | id, host |
						data = (host.housing_data || {})
						host_data = {
							name: host.user.name,
							street_address: data['address'],
							email: host.user.email,
							phone: data['phone'],
							availability: data['availability'].present? && data['availability'][1].present? ? view_context.date_span(data['availability'][0].to_date, data['availability'][1].to_date) : '',
							considerations: (data['considerations'].map { | consideration | view_context._"articles.conference_registration.host.considerations.#{consideration}" }).join(', '),
							empty: '',
							guests: {
								columns: [:name, :area, :email, :arrival_departure, :allergies, :food, :companion, :city],
								keys: {
									name: 'forms.labels.generic.name',
									area: 'articles.workshops.headings.space',
									email: 'forms.labels.generic.email',
									arrival_departure: 'articles.admin.housing.headings.arrival_departure',
									companion: 'forms.labels.generic.companion',
									city: 'forms.labels.generic.city',
									food: 'forms.labels.generic.food',
									allergies: 'forms.labels.generic.allergies'
								},
								column_types: {
									name: :bold
								},
								data: []
							}
						}

						@housing_data[id][:guests].each do | space, space_data |
							space_data.each do | guest_id, guest_data |
								guest = guest_data[:guest]
								if guest.present?
									companion = view_context.companion(guest)

									host_data[:guests][:data] << {
										name: guest.user.name,
										area: (view_context._"forms.labels.generic.#{space}"),
										email: guest.user.email,
										arrival_departure: guest.arrival.present? && guest.departure.present? ? view_context.date_span(guest.arrival.to_date, guest.departure.to_date) : '',
										companion: companion.present? ? (companion.is_a?(User) ? companion.name : (view_context._"articles.conference_registration.terms.registration_status.#{companion}")) : '',
										city: guest.city,
										food: (view_context._"articles.conference_registration.questions.food.#{guest.food}"),
										allergies: guest.allergies
									}
								end
							end
						end

						@excel_data[:data] << host_data
					end
					return respond_to do | format |
						format.xlsx { render xlsx: :stats, filename: "housing" }
					end
				end
			when :locations
				@locations = EventLocation.where(:conference_id => @this_conference.id)
			when :events
				@event = Event.new(locale: I18n.locale)
				@events = Event.where(:conference_id => @this_conference.id)
				@day = nil
				@time = nil
				@length = 1.5
			when :meals
				@meals = Hash[(@this_conference.meals || {}).map{ |k, v| [k.to_i, v] }].sort.to_h
			when :workshop_times
				get_block_data
				@workshop_blocks << {
					'time' => nil,
					'length' => 1.0,
					'days' => []
				}
			when :schedule
				@can_edit = true
				@entire_page = true
				get_scheule_data
			end
		when :confirm_email
			@page_title = "articles.conference_registration.headings.#{@this_conference.registration_status == :open ? '': 'Pre_'}Registration_Details"
		end

	end

	def get_housing_data
		@hosts = {}
		@guests = {}
		ConferenceRegistration.where(:conference_id => @this_conference.id).each do | registration |
			if registration.can_provide_housing
				@hosts[registration.id] = registration
			elsif registration.housing.present? && registration.housing != 'none'
				@guests[registration.id] = registration
			end
		end
	end

	def analyze_housing
		get_housing_data unless @hosts.present? && @guests.present?

		@housing_data = {}
		@hosts_affected_by_guests = {}
		@hosts.each do | id, host |
			@hosts[id].housing_data ||= {}
			@housing_data[id] = { guests: {}, space: {} }
			@hosts[id].housing_data['space'] ||= {}
			@hosts[id].housing_data['space'].each do | s, size |
				size = (size || 0).to_i
				@housing_data[id][:guests][s.to_sym] = {}
				@housing_data[id][:space][s.to_sym] = size
			end
		end
		
		@guests_housed = 0

		@guests.each do | guest_id, guest |
			data = guest.housing_data || {}
			@hosts_affected_by_guests[guest_id] ||= []

			if data['host']
				@guests_housed += 1
				host_id = (data['host'].present? ? data['host'].to_i : nil)
				host = host_id.present? ? @hosts[host_id] : nil

				# make sure the host was found and that they are still accepting guests
				if host.present? && host.can_provide_housing
					@hosts_affected_by_guests[guest_id] << host_id

					space = (data['space'] || :bed).to_sym

					@housing_data[host_id] ||= {}
					host_data = host.housing_data
					unless @housing_data[host_id][:guests][space].present?
						@housing_data[host_id][:guests][space] ||= {}
						@housing_data[host_id][:space][space] ||= 0
					end

					@housing_data[host_id][:guests][space][guest_id] = { guest: guest }

					@housing_data[host_id][:guest_data] ||= {}
					@housing_data[host_id][:guest_data][guest_id] = { warnings: {}, errors: {} }

					@housing_data[host_id][:guest_data][guest_id][:warnings][:dates] = {} unless view_context.available_dates_match?(host, guest)

					if (guest.housing == 'house' && space == :tent) ||
						(guest.housing == 'tent' && (space == :bed_space || space == :floor_space))
						@housing_data[host_id][:guest_data][guest_id][:warnings][:space] = { actual: (view_context._"forms.labels.generic.#{space.to_s}"), expected: (view_context._"articles.conference_registration.questions.housing.#{guest.housing}")}
					end

					companions = data['companions'] || []
					companions.each do | companion |
						user = User.find_by_email(companion)
						if user.present?
							reg = ConferenceRegistration.find_by(
									:user_id => user.id,
									:conference_id => @this_conference.id
								)
							if reg.present? && @guests[reg.id].present?
								housing_data = reg.housing_data || {}
								companion_host = housing_data['host'].present? ? housing_data['host'].to_i : nil
								@hosts_affected_by_guests[guest_id] << companion_host
								if companion_host != host_id && reg.housing.present? && reg.housing != 'none'
									# set this as an error if the guest has selected only one other to stay with, but if they have requested to stay with more, make this only a warning
									@housing_data[host_id][:guest_data][guest_id][:warnings][:companions] = { name: "<strong>#{reg.user.name}</strong>".html_safe, id: reg.id }
								end
							end
						end
					end
				else
					# make sure the housing data is empty if the host wasn't found, just in case something happened to the host
					@guests[guest_id].housing_data ||= {}
					@guests[guest_id].housing_data['host'] = nil
					@guests[guest_id].housing_data['space'] = nil
				end
			end
		end
		
		@hosts.each do | id, host |
			host_data = host.housing_data

			@hosts[id].housing_data['space'].each do | space, size |
				# make sure the host isn't overbooked
				space = space.to_sym
				space_available = (size || 0).to_i
				@housing_data[id][:warnings] ||= {}
				@housing_data[id][:warnings][:space] ||= {}
				@housing_data[id][:warnings][:space][space] ||= []

				if @housing_data[id][:guests][space].size > space_available
					@housing_data[id][:warnings][:space][space] << :overbooked
				end
			end
		end

		return @hosts_affected_by_guests
	end

	def admin_update
		set_conference
		# set_conference_registration
		return do_403 unless @this_conference.host? current_user

		# set the page title in case we render instead of redirecting
		@page_title = 'articles.conference_registration.headings.Administration'
		@register_template = :administration
		@admin_step = params[:admin_step]

		case params[:admin_step]
		when 'edit'
			case params[:button]
			when 'save'
				@this_conference.registration_status = params[:registration_status]
				@this_conference.info = LinguaFranca::ActiveRecord::UntranslatedValue.new(params[:info]) unless @this_conference.info! == params[:info]

				params[:info_translations].each do | locale, value |
					@this_conference.set_column_for_locale(:info, locale, value, current_user.id) unless value == @this_conference._info(locale)
				end
				@this_conference.save
				return redirect_to administration_step_path(@this_conference.slug, :edit)
			when 'add_member'
				org = nil
				@this_conference.organizations.each do | organization |
					org = organization if organization.id == params[:org_id].to_i
				end
				org.users << (User.get params[:email])
				org.save
				return redirect_to administration_step_path(@this_conference.slug, :edit)
			end
		when 'payment'
			case params[:button]
			when 'save'
				@this_conference.payment_message = LinguaFranca::ActiveRecord::UntranslatedValue.new(params[:payment_message]) unless @this_conference.payment_message! == params[:payment_message]

				params[:payment_message_translations].each do | locale, value |
					@this_conference.set_column_for_locale(:payment_message, locale, value, current_user.id) unless value == @this_conference._payment_message(locale)
				end

				@this_conference.payment_amounts = ((params[:payment_amounts] || {}).values.map &:to_i) - [0]

				@this_conference.paypal_email_address = params[:paypal_email_address]
				@this_conference.paypal_username = params[:paypal_username]
				@this_conference.paypal_password = params[:paypal_password]
				@this_conference.paypal_signature = params[:paypal_signature]
				@this_conference.save
				return redirect_to administration_step_path(@this_conference.slug, :payment)
			end
		when 'housing'
			# modify the guest data

			if params[:button] == 'get-guest-list'
				# get_housing_data
				analyze_housing
				return render partial: 'conferences/admin/select_guest_table', locals: { host: @hosts[params['host'].to_i], space: params['space'] }
			elsif params[:button] == 'set-guest'
				guest = ConferenceRegistration.where(
						id: params[:guest].to_i,
						conference_id: @this_conference.id
					).limit(1).first

				guest.housing_data ||= {}
				guest.housing_data['space'] = params[:space]
				guest.housing_data['host'] = params[:host].to_i
				guest.save!
				
				analyze_housing

				return render partial: 'conferences/admin/hosts_table'
			elsif params[:button] == 'remove-guest'
				guest = ConferenceRegistration.where(
						id: params[:guest].to_i,
						conference_id: @this_conference.id
					).limit(1).first

				guest.housing_data ||= {}
				guest.housing_data.delete('space')
				guest.housing_data.delete('host')
				guest.save!
				
				analyze_housing

				return render partial: 'conferences/admin/hosts_table'
			end
		when 'broadcast'
			@hide_description = true
			@subject = params[:subject]
			@body = params[:body]
			@send_to = params[:send_to]
			@register_template = :administration
			if params[:button] == 'send'
				view_context.broadcast_to(@send_to).each do | user |
					UserMailer.send_mail :broadcast do
						[
							"#{request.protocol}#{request.host_with_port}",
							@subject,
							@body,
							user,
							@this_conference
						]
					end
				end
				return redirect_to administration_step_path(@this_conference.slug, :broadcast_sent)
			elsif params[:button] == 'preview'
				@send_to_count = view_context.broadcast_to(@send_to).size
				@broadcast_step = :preview
			elsif params[:button] == 'test'
				@broadcast_step = :test
				UserMailer.send_mail :broadcast do
					[
						"#{request.protocol}#{request.host_with_port}",
						@subject,
						@body,
						current_user,
						@this_conference
					]
				end
				@send_to_count = view_context.broadcast_to(@send_to).size
			end
			return render 'conferences/register'
		when 'locations'
			case params[:button]
			when 'edit'
				@location = EventLocation.find_by! id: params[:id].to_i, conference_id: @this_conference.id
				return render 'conferences/register'
			when 'save'
				location = EventLocation.find_by! id: params[:id].to_i, conference_id: @this_conference.id
				empty_param = get_empty(params, [:title, :address, :space])
				if empty_param.present?
					flash[:error] = (view_context._"errors.messages.fields.#{empty_param.to_s}.empty")
				else
					location.title = params[:title]
					location.address = params[:address]
					location.amenities = (params[:needs] || {}).keys.to_json
					location.space = params[:space]
					location.save!
				end
				return redirect_to administration_step_path(@this_conference.slug, :locations)
			when 'cancel'
				return redirect_to administration_step_path(@this_conference.slug, :locations)
			when 'delete'
				location = EventLocation.find_by! id: params[:id].to_i, conference_id: @this_conference.id
				location.destroy
				return redirect_to administration_step_path(@this_conference.slug, :locations)
			when 'create'
				empty_param = get_empty(params, [:title, :address, :space])
				if empty_param.present?
					flash[:error] = (view_context._"errors.messages.fields.#{empty_param.to_s}.empty")
				else
					EventLocation.create(
							conference_id: @this_conference.id,
							title: params[:title],
							address: params[:address],
							amenities: (params[:needs] || {}).keys.to_json,
							space: params[:space]
						)
				end
				return redirect_to administration_step_path(@this_conference.slug, :locations)
			end
		when 'meals'
			case params[:button]
			when 'add_meal'
				@this_conference.meals ||= {}
				@this_conference.meals[(Date.parse(params[:day]) + params[:time].to_f.hours).to_time.to_i] = {
					title: params[:title],
					info: params[:info],
					location: params[:event_location],
					day: params[:day],
					time: params[:time]
				}
				@this_conference.save!
				return redirect_to administration_step_path(@this_conference.slug, :meals)
			when 'delete'
				@this_conference.meals ||= {}
				@this_conference.meals.delete params[:meal]
				@this_conference.save!
				return redirect_to administration_step_path(@this_conference.slug, :meals)
			end
		when 'events'
			case params[:button]
			when 'edit'
				@event = Event.find_by!(conference_id: @this_conference.id, id: params[:id])
				@day = @event.start_time.midnight
				@time = view_context.hour_span(@day, @event.start_time)
				@length = view_context.hour_span(@event.start_time, @event.end_time)
				return render 'conferences/register'
			when 'save'
				if params[:id].present?
					event = Event.find_by!(conference_id: @this_conference.id, id: params[:id])
				else
					event = Event.new(conference_id: @this_conference.id, locale: I18n.locale)
				end

				# save title and info
				event.title = LinguaFranca::ActiveRecord::UntranslatedValue.new(params[:title]) unless event.title! == params[:title]
				event.info = LinguaFranca::ActiveRecord::UntranslatedValue.new(params[:info]) unless event.info! == params[:info]
				
				# save schedule data
				event.event_location_id = params[:event_location]
				event.start_time = Date.parse(params[:day]) + params[:time].to_f.hours
				event.end_time = event.start_time + params[:time_span].to_f.hours

				# save translations
				(params[:info_translations] || {}).each do | locale, value |
					event.set_column_for_locale(:title, locale, value, current_user.id) unless value = event._title(locale)
					event.set_column_for_locale(:info, locale, value, current_user.id) unless value = event._info(locale)
				end

				event.save

				return redirect_to administration_step_path(@this_conference.slug, :events)
			when 'cancel'
				return redirect_to administration_step_path(@this_conference.slug, :events)
			end
		when 'workshop_times'
			case params[:button]
			when 'save_block'
				@this_conference.workshop_blocks ||= []
				@this_conference.workshop_blocks[params[:workshop_block].to_i] = {
					'time' => params[:time],
					'length' => params[:time_span],
					'days' => params[:days].keys
				}
				@this_conference.save
				return redirect_to administration_step_path(@this_conference.slug, :workshop_times)
			end
		when 'schedule'
			success = false
			
			case params[:button]
			when 'schedule_workshop'
				workshop = Workshop.find_by!(conference_id: @this_conference.id, id: params[:id])
				booked = false
				workshop.event_location_id = params[:event_location]
				block_data = params[:workshop_block].split(':')
				workshop.block = {
					day: block_data[0].to_i,
					block: block_data[1].to_i
				}

				# make sure this spot isn't already taken
				Workshop.where(:conference_id => @this_conference.id).each do | w |
					if request.xhr?
						if w.block.present? &&
								w.id != workshop.id &&
								w.block['day'] == workshop.block['day'] &&
								w.block['block'] == workshop.block['block'] &&
								w.event_location_id == workshop.event_location_id
							return render json: [ {
									selector: '.already-booked',
									className: 'already-booked is-true'
								} ]
						end
					else
						return redirect_to administration_step_path(@this_conference.slug, :schedule)
					end
				end
				
				workshop.save!
				success = true
			when 'deschedule_workshop'
				workshop = Workshop.find_by!(conference_id: @this_conference.id, id: params[:id])
				workshop.event_location_id = nil
				workshop.block = nil
				workshop.save!
				success = true
			when 'publish'
				@this_conference.workshop_schedule_published = !@this_conference.workshop_schedule_published
				@this_conference.save
				return redirect_to administration_step_path(@this_conference.slug, :schedule)
			end

			if success
				if request.xhr?
					@can_edit = true
					@entire_page = false
					get_scheule_data
					schedule = render_to_string partial: 'conferences/admin/schedule'
					return render json: [ {
							globalSelector: '#schedule-preview',
							html: schedule
						}, {
							globalSelector: "#workshop-#{workshop.id}",
							className: workshop.block.present? ? 'booked' : 'not-booked'
						}, {
							globalSelector: "#workshop-#{workshop.id} .already-booked",
							className: 'already-booked'
						} ]
				else
					return redirect_to administration_step_path(@this_conference.slug, :schedule)
				end
			end
		end
		do_404
	end

	def workshops
		set_conference
		set_conference_registration!
		@workshops = Workshop.where(:conference_id => @this_conference.id)
		@my_workshops = Workshop.joins(:workshop_facilitators).where(:workshop_facilitators => {:user_id => current_user.id}, :conference_id => @this_conference.id)
		render 'workshops/index'
	end

	def view_workshop
		set_conference
		set_conference_registration!
		@workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
		return do_404 unless @workshop

		@translations_available_for_editing = []
		I18n.backend.enabled_locales.each do |locale|
			@translations_available_for_editing << locale if @workshop.can_translate?(current_user, locale)
		end
		@page_title = 'page_titles.conferences.View_Workshop'
		@register_template = :workshops

		render 'workshops/show'
	end

	def create_workshop
		set_conference
		set_conference_registration!
		@workshop = Workshop.new
		@languages = [I18n.locale.to_sym]
		@needs = []
		@page_title = 'page_titles.conferences.Create_Workshop'
		@register_template = :workshops
		render 'workshops/new'
	end

	def translate_workshop
		@is_translating = true
		@translation = params[:locale]
		@page_title = 'page_titles.conferences.Translate_Workshop'
		@page_title_vars = { language: view_context.language_name(@translation) }
		@register_template = :workshops

		edit_workshop
	end

	def edit_workshop
		set_conference
		set_conference_registration!
		@workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
		
		return do_404 unless @workshop.present?

		@page_title ||= 'page_titles.conferences.Edit_Workshop'

		@can_edit = @workshop.can_edit?(current_user)

		@is_translating ||= false
		if @is_translating
			return do_404 if @translation.to_s == @workshop.locale.to_s || !I18n.backend.enabled_locales.include?(@translation.to_s)
			return do_403 unless @workshop.can_translate?(current_user, @translation)

			@title = @workshop._title(@translation)
			@info = @workshop._info(@translation)
		else
			return do_403 unless @can_edit

			@title = @workshop.title
			@info = @workshop.info
		end

		@needs = JSON.parse(@workshop.needs || '[]').map &:to_sym
		@languages = JSON.parse(@workshop.languages || '[]').map &:to_sym
		@space = @workshop.space.to_sym if @workshop.space
		@theme = @workshop.theme.to_sym if @workshop.theme
		@notes = @workshop.notes
		@register_template = :workshops

		render 'workshops/new'
	end

	def delete_workshop
		set_conference
		set_conference_registration!
		@workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)

		return do_404 unless @workshop.present?
		return do_403 unless @workshop.can_delete?(current_user)

		if request.post?
			if params[:button] == 'confirm'
				if @workshop
					@workshop.workshop_facilitators.destroy_all
					@workshop.destroy
				end

				return redirect_to register_step_path(@this_conference.slug, 'workshops')
			end
			return redirect_to view_workshop_url(@this_conference.slug, @workshop.id)
		end
		@register_template = :workshops

		render 'workshops/delete'
	end
	
	def save_workshop
		set_conference
		set_conference_registration!

		if params[:button].to_sym != :save
			if params[:workshop_id].present?
				return redirect_to view_workshop_url(@this_conference.slug, params[:workshop_id])
			end
			return redirect_to register_step_path(@this_conference.slug, 'workshops')
		end

		if params[:workshop_id].present?
			workshop = Workshop.find(params[:workshop_id])
			return do_404 unless workshop.present?
			can_edit = workshop.can_edit?(current_user)
		else
			workshop = Workshop.new(:conference_id => @this_conference.id)
			workshop.workshop_facilitators = [WorkshopFacilitator.new(:user_id => current_user.id, :role => :creator)]
			can_edit = true
		end

		title = params[:title]
		info  = params[:info].gsub(/^\s*(.*?)\s*$/, '\1')

		if params[:translation].present? && workshop.can_translate?(current_user, params[:translation])
			old_title = workshop._title(params[:translation])
			old_info = workshop._info(params[:translation])

			do_save = false

			unless title == old_title
				workshop.set_column_for_locale(:title, params[:translation], title, current_user.id)
				do_save = true
			end
			unless info == old_info
				workshop.set_column_for_locale(:info, params[:translation], info, current_user.id)
				do_save = true
			end
			
			# only save if the text has changed, if we want to make sure only to update the translator id if necessary
			workshop.save_translations if do_save
		elsif can_edit
			workshop.title              = title
			workshop.info               = info
			workshop.languages          = (params[:languages] || {}).keys.to_json
			workshop.needs              = (params[:needs] || {}).keys.to_json
			workshop.theme              = params[:theme] == 'other' ? params[:other_theme] : params[:theme]
			workshop.space              = params[:space]
			workshop.notes              = params[:notes]
			workshop.needs_facilitators = params[:needs_facilitators].present?
			workshop.save

			# Rouge nil facilitators have been know to be created, just destroy them here now
			WorkshopFacilitator.where(:user_id => nil).destroy_all
		else
			return do_403
		end

		redirect_to view_workshop_url(@this_conference.slug, workshop.id)
	end

	def toggle_workshop_interest
		set_conference
		set_conference_registration!
		workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
		return do_404 unless workshop

		# save the current state
		interested = workshop.interested? current_user
		# remove all associated fields
		WorkshopInterest.delete_all(:workshop_id => workshop.id, :user_id => current_user.id)

		# creat the new interest row if we weren't interested before
		WorkshopInterest.create(:workshop_id => workshop.id, :user_id => current_user.id) unless interested

		if request.xhr?
			render json: [
				{
					selector: '.interest-button',
					html: view_context.interest_button(workshop)
				},
				{
					selector: '.interest-text',
					html: view_context.interest_text(workshop)
				}
			]
		else
			# go back to the workshop
			redirect_to view_workshop_url(@this_conference.slug, workshop.id)
		end
	end

	def facilitate_workshop
		set_conference
		set_conference_registration!
		@workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
		return do_404 unless @workshop
		return do_403 if @workshop.facilitator?(current_user) || !current_user

		@register_template = :workshops
		render 'workshops/facilitate'
	end

	def facilitate_request
		set_conference
		set_conference_registration!
		workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
		return do_404 unless workshop
		return do_403 if workshop.facilitator?(current_user) || !current_user

		# create the request by making the user a facilitator but making their role 'requested'
		WorkshopFacilitator.create(user_id: current_user.id, workshop_id: workshop.id, role: :requested)

		UserMailer.send_mail :workshop_facilitator_request do
			{
				:args => [ workshop, current_user, params[:message] ]
			}
		end

		redirect_to sent_facilitate_workshop_url(@this_conference.slug, workshop.id)
	end

	def sent_facilitate_request
		set_conference
		set_conference_registration!
		@workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
		return do_404 unless @workshop
		return do_403 unless @workshop.requested_collaborator?(current_user)

		@register_template = :workshops
		render 'workshops/facilitate_request_sent'
	end

	def approve_facilitate_request
		return do_403 unless logged_in?
		set_conference
		set_conference_registration!
		workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
		return do_404 unless workshop.present?
		
		user_id = params[:user_id].to_i
		action = params[:approve_or_deny].to_sym
		user = User.find(user_id)
		case action
		when :approve
			if workshop.active_facilitator?(current_user) && workshop.requested_collaborator?(User.find(user_id))
				f = WorkshopFacilitator.find_by_workshop_id_and_user_id(
						workshop.id, user_id)
				f.role = :collaborator
				f.save
				UserMailer.send_mail :workshop_facilitator_request_approved, user.locale do
					[ workshop, user ]
				end
				return redirect_to view_workshop_url(@this_conference.slug, workshop.id)		
			end
		when :deny
			if workshop.active_facilitator?(current_user) && workshop.requested_collaborator?(User.find(user_id))
				WorkshopFacilitator.delete_all(
					:workshop_id => workshop.id,
					:user_id => user_id)
				UserMailer.send_mail :workshop_facilitator_request_denied, user.locale do
					[ workshop, user ]
				end
				return redirect_to view_workshop_url(@this_conference.slug, workshop.id)		
			end
		when :remove
			if workshop.can_remove?(current_user, user)
				WorkshopFacilitator.delete_all(
					:workshop_id => workshop.id,
					:user_id => user_id)
				return redirect_to view_workshop_url(@this_conference.slug, workshop.id)
			end
		when :switch_ownership
			if workshop.creator?(current_user)
				f = WorkshopFacilitator.find_by_workshop_id_and_user_id(
						workshop.id, current_user.id)
				f.role = :collaborator
				f.save
				f = WorkshopFacilitator.find_by_workshop_id_and_user_id(
						workshop.id, user_id)
				f.role = :creator
				f.save
				return redirect_to view_workshop_url(@this_conference.slug, workshop.id)
			end
		end

		return do_403
	end

	def add_workshop_facilitator
		set_conference
		set_conference_registration!

		user = User.find_by_email(params[:email])

		# create the user if they don't exist and send them a link to register
		unless user
			user = User.create(email: params[:email])
			generate_confirmation(user, register_path(@this_conference.slug))
		end

		workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)

		return do_404 unless workshop && current_user

		unless workshop.facilitator?(user)
			WorkshopFacilitator.create(user_id: user.id, workshop_id: workshop.id, role: :collaborator)
			
			UserMailer.send_mail :workshop_facilitator_request_approved, user.locale do
				[ workshop, user ]
			end
		end

		return redirect_to view_workshop_url(@this_conference.slug, params[:workshop_id])
	end

	def add_comment
		set_conference
		set_conference_registration!
		workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
		
		return do_404 unless workshop && current_user

		if params[:button] == 'reply'
			comment = Comment.find_by!(id: params[:comment_id].to_i, model_type: :workshops, model_id: workshop.id)
			new_comment = comment.add_comment(current_user, params[:reply])

			unless comment.user.id == current_user.id
				UserMailer.send_mail :workshop_comment, comment.user.locale do
					[ workshop, new_comment, comment.user ]
				end
			end
		elsif params[:button] = 'add_comment'
			new_comment = workshop.add_comment(current_user, params[:comment])

			workshop.active_facilitators.each do | u |
				unless u.id == current_user.id
					UserMailer.send_mail :workshop_comment, u.locale do
						[ workshop, new_comment, u ]
					end
				end
			end
		else
			return do_404
		end

		return redirect_to view_workshop_url(@this_conference.slug, workshop.id, anchor: "comment-#{new_comment.id}")
	end

	helper_method :registration_steps
	helper_method :current_registration_steps
	helper_method :registration_complete?

	def registration_steps(conference = nil)
		conference ||= @this_conference || @conference
		status = conference.registration_status
		# return [] unless status == :pre || status == :open

		steps = status == :pre || status == :open ? [
				:policy,
				:contact_info,
				:questions,
				:hosting,
				:payment,
				:workshops
			] : []
		
		steps -= [:questions] unless status == :open
		steps -= [:payment] unless status == :open && conference.paypal_email_address.present? && conference.paypal_username.present? && conference.paypal_password.present? && conference.paypal_signature.present?
		if @registration.present?
			if view_context.same_city?(@registration.city, view_context.location(conference.location, conference.locale))
				steps -= [:questions]
				
				# if this is a housing provider that is not attending the conference, remove these steps
				if @registration.is_attending == 'n'
					steps -= [:payment, :workshops]
				end
			else
				steps -= [:hosting]
			end
		else
			steps -= [:hosting, :questions]
		end

		steps += [:administration] if conference.host?(current_user)

		return steps
	end

	def required_steps(conference = nil)
		# return the intersection of current steps and required steps
		registration_steps(conference || @this_conference || @conference) & # current steps
			[:policy, :contact_info, :hosting, :questions] # all required steps
	end

	def registration_complete?(registration = @registration)
		completed_steps = registration.steps_completed || []
		required_steps(registration.conference).each do | step |
			return true if step == :workshops
			return false unless completed_steps.include?(step.to_s)
		end
		return true
	end

	def current_registration_steps(registration = @registration)
		return nil unless registration.present?

		steps = registration_steps(registration.conference)
		current_steps = []
		disable_steps = false
		completed_steps = registration.steps_completed || []
		registration_complete = registration_complete?(registration)
		steps.each do | step |
			# disable the step if we've already found an incomplete step
			enabled = !disable_steps || registration_complete
			# record whether or not we've found an incomplete step
			disable_steps ||= !completed_steps.include?(step.to_s)

			current_steps << {
				name:    step,
				enabled: enabled
			}
		end
		return current_steps
	end

	def current_step(registration = @registration)
		completed_steps = registration.steps_completed || []
		(registration_steps(registration.conference) || []).each do | step |
			return step unless completed_steps.include?(step.to_s)
		end
		return registration_steps(registration.conference).last
	end

	rescue_from ActiveRecord::RecordNotFound do |exception|
		do_404
	end

	rescue_from ActiveRecord::PremissionDenied do |exception|
		if logged_in?
			redirect_to :register
		else
			@register_template = :confirm_email
			@page_title = "articles.conference_registration.headings.#{@this_conference.registration_status == :open ? '': 'Pre_'}Registration_Details"
			render :register
		end
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_conference
			@this_conference = Conference.find_by!(slug: params[:conference_slug] || params[:slug])
		end

		def set_conference_registration
			@registration = logged_in? ? ConferenceRegistration.find_by(:user_id => current_user.id, :conference_id => @this_conference.id) : nil
		end

		def set_conference_registration!
			@registration = set_conference_registration
			raise ActiveRecord::PremissionDenied unless @registration.present?
		end

		def set_or_create_conference_registration
			set_conference_registration
			return @registration if @registration.present?

			@registration ||= ConferenceRegistration.new(
					conference:      @this_conference,
					user_id:         current_user.id,
					steps_completed: []
				)
			last_registration_data = ConferenceRegistration.where(user_id: current_user.id).order(created_at: :desc).limit(1).first

			if last_registration_data.present?
				if last_registration_data['languages'].present? && current_user.languages.blank?
					current_user.languages = JSON.parse(last_registration_data['languages'])
					current_user.save!
				end
				
				@registration.city = last_registration_data.city if last_registration_data.city.present?
			end
		end

		# Only allow a trusted parameter "white list" through.
		def conference_params
			params.require(:conference).permit(:title, :slug, :start_date, :end_date, :info, :poster, :cover, :workshop_schedule_published, :registration_status, :meals_provided, :meal_info, :travel_info, :conference_type_id, conference_types: [:id])
		end

		def update_field_position(field_id, position)
			data = []
			for i in 0..@conference.conference_registration_form_fields.length
				f = @conference.conference_registration_form_fields[i]
				if f.registration_form_field_id == field_id
					data << (f.registration_form_field_id.to_s + ' == ' + field_id.to_s + ' [position: ' + position.to_s + ' == ' + f.position.to_s + ']')
					f.update_attributes(:position => position)
					return
				end
			end
		end

		def update_registration_data
			if session[:registration][:registration_id]
				registration = ConferenceRegistration.find(session[:registration][:registration_id])
				registration.data = YAML.load(registration.data).merge(session[:registration]).to_yaml
				registration.save!
			end
		end

		def complete_registration
			if session[:registration][:registration_id]
				registration = ConferenceRegistration.find(session[:registration][:registration_id])
				session[:registration] = YAML.load(registration.data)
				registration.completed = true
				if registration.is_confirmed
					registration.complete = true

					user = User.find_by(:email => session[:registration][:email])
					if !user
						user = User.new(:email => session[:registration][:email], :username => session[:registration][:user][:username], :role => 'user')
					end
					user.firstname = session[:registration][:user][:firstname]
					user.lastname = session[:registration][:user][:lastname]
					user.save!

					if session[:registration][:is_participant]
						UserOrganizationRelationship.destroy_all(:user_id => user.id)
						session[:registration][:organizations].each { |org_id|
							found = false
							org = Organization.find(org_id.is_a?(Array) ? org_id.first : org_id)
							org.user_organization_relationships.each {|rel| found = found && rel.user_id == user.id}
							if !found
								org.user_organization_relationships << UserOrganizationRelationship.new(:user_id => user.id, :relationship => UserOrganizationRelationship::Administrator)
							end
							org.save!
						}

						if session[:registration][:new_organization]
							session[:registration][:new_organization].each { |new_org|
								found = false
								org = Organization.find_by(:email_address => new_org[:email])
								if org.nil?
									org = Organization.new(
										:name			=> new_org[:name],
										:email_address	=> new_org[:email],
										:info			=> new_org[:info]
									)
									org.locations << Location.new(:country => new_org[:country], :territory => new_org[:territory], :city => new_org[:city], :street => new_org[:street])
								end
								org.user_organization_relationships.each {|rel| found = found && rel.user_id == user.id}
								if !found
									org.user_organization_relationships << UserOrganizationRelationship.new(:user_id => user.id, :relationship => UserOrganizationRelationship::Administrator)
								end
								org.save!
								org.avatar = "#{request.protocol}#{request.host_with_port}/#{new_org[:logo]}"
								cover = get_panoramio_image(org.locations.first)
								org.cover = cover[:image]
								org.cover_attribution_id = cover[:attribution_id]
								org.cover_attribution_user_id = cover[:attribution_user_id]
								org.cover_attribution_name = cover[:attribution_user_name]
								org.cover_attribution_src = cover[:attribution_src]
								org.save!
							}
						end

						if session[:registration][:is_workshop_host] && session[:registration][:workshop]
							session[:registration][:workshop].each { |new_workshop|
								workshop = Workshop.new(
									:conference_id					=> @conference.id,
									:title							=> new_workshop[:title],
									:info							=> new_workshop[:info],
									:workshop_stream_id				=> WorkshopStream.find_by(:slug => new_workshop[:stream]).id,
									:workshop_presentation_style	=> WorkshopPresentationStyle.find_by(:slug => new_workshop[:presentation_style])
								)
								workshop.workshop_facilitators << WorkshopFacilitator.new(:user_id => user.id)
								workshop.save!
							}
						end
					end

					send_confirmation_confirmation(registration, session[:registration])

					session.delete(:registration)
					session[:registration] = Hash.new
					session[:registration][:registration_id] = registration.id
				end
				registration.save!
			end
		end

		def create_registration
			if session[:registration][:registration_id].blank? || !ConferenceRegistration.exists?(session[:registration][:registration_id])
				registration = ConferenceRegistration.new(
					:conference_id		=> @conference.id,
					:user_id			=> session[:registration][:user][:id],
					:email				=> session[:registration][:email],
					:is_attending		=> 'y',
					:is_participant		=> session[:registration][:is_participant],
					:is_volunteer		=> session[:registration][:is_volunteer],
					:is_confirmed		=> false,
					:complete			=> false,
					:completed			=> false,
					:confirmation_token	=> rand_hash(32, :conference_registration, :confirmation_token),
					:payment_confirmation_token	=> rand_hash(32, :conference_registration, :payment_confirmation_token),
					:data				=> session[:registration].to_yaml
				)
				registration.save!
				session[:registration][:registration_id] = registration.id
				send_confirmation(registration, session[:registration])
			end
		end

		def send_confirmation(registration = nil, data = nil)
			registration ||= ConferenceRegistration.find(session[:registration][:registration_id])
			data ||= YAML.load(registration.data)
			UserMailer.conference_registration_email(@conference, data, registration).deliver
		end

		def send_confirmation_confirmation(registration = nil, data = nil)
			registration ||= ConferenceRegistration.find(session[:registration][:registration_id])
			data ||= YAML.load(registration.data)
			UserMailer.conference_registration_confirmed_email(@conference, data, registration).deliver
		end

		def send_payment_received(registration = nil, data = nil)
			registration ||= ConferenceRegistration.find(session[:registration][:registration_id])
			data ||= YAML.load(registration.data)
			UserMailer.conference_registration_payment_received(@conference, data, registration).deliver
		end

		def get_empty(hash, keys)
			keys = [keys] unless keys.is_a?(Array)
			keys.each do | key |
				puts " ===== #{key} = #{hash[key]} ===== "
				return key unless hash[key].present?
			end
			return nil
		end

	def PayPal!
		Paypal::Express::Request.new(
			username:  @this_conference.paypal_username,
			password:  @this_conference.paypal_password,
			signature: @this_conference.paypal_signature
		)
	end

	def PayPalRequest(amount)
		Paypal::Payment::Request.new(
			:currency_code => 'USD',   # if nil, PayPal use USD as default
			:description   => 'Conference Registration',    # item description
			:quantity      => 1,      # item quantity
			:amount        => amount.to_f,   # item value
			:custom_fields => {
				CARTBORDERCOLOR: "00ADEF",
				LOGOIMG: "https://en.bikebike.org/assets/bblogo-paypal.png"
			}
		)
	end
end
