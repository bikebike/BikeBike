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

	# GET /conferences
	def index
		@conference_type = nil
		if params['conference_type']
			@conference_type = ConferenceType.find_by!(:slug => params['conference_type'])
			@conferences = Conference.where(:conference_type_id => @conference_type.id)
		else
			@conferences = Conference.all
		end
	end

	# GET /conferences/1
	def show
	end

	# GET /conferences/new
	def new
		@conference = Conference.new
		@conference.build_conference_type
	end

	# GET /conferences/1/edit
	def edit
		set_conference
		set_conference_registration
		raise ActiveRecord::PremissionDenied unless (current_user && @this_conference.host?(current_user))
	end

	# PATCH/PUT /conferences/1
	def save
		set_conference
		set_conference_registration
		raise ActiveRecord::PremissionDenied unless (current_user && @this_conference.host?(current_user))

		@this_conference.info = params[:info]
		@this_conference.save

		redirect_to edit_conference_path(@this_conference)
	end

	def hosts
		set_conference
		@conference.conference_host_organizations.build
	end

	def nonhosts
		set_conference
		@available_orgs = Organization.where(["id NOT IN (?)", @conference.organizations.map(&:id) + (params[:added] || [])])
		html = '<h2>Select an Organization</h2><div id="select-organization-list">'
		@available_orgs.each do |organization|
			html += '<a href="#" class="organization-preview" data-id="' + organization.id.to_s + '"><img src="' + (organization.avatar.url :thumb) + '" /><div class="username">' + (organization.name) + '</div></a>'
		end
		render :text => (html + '</div>')
	end

	def registration
		set_conference
		@sub_action = 'registration' + (params[:sub_action] ? '_' + params[:sub_action] : '')
		if params[:sub_action] == 'form'
			@registration_form_field = RegistrationFormField.new
			@registration_form_fields = RegistrationFormField.where(["id NOT IN (?)", @conference.registration_form_fields.map(&:id)])
		end
	end

	def register_submit
		next_step = nil
		if !session[:registration]
			session[:registration] = Hash.new
			session[:registration][:path] = Array.new
		end

		case session[:registration_step] || params['step']
			when 'confirm'
				if session[:registration][:is_participant]
					@registration = ConferenceRegistration.find(session[:registration][:registration_id])
					if @registration.completed
						complete_registration
						next_step = 'thanks'
					else
						next_step = 'organizations'
					end
				else
					complete_registration
					next_step = 'thanks'
				end
			when 'register'
				session[:registration][:email] = params[:email]
				registration = ConferenceRegistration.find_by(:email => params[:email])
				if !registration.nil?
					session[:registration] = YAML.load(registration.data)
					session[:registration][:registration_id] = registration.id
					next_step = (registration.completed.blank? && registration.is_participant.present? ? 'organizations' : 'thanks')
				else
					if !session[:registration][:user] || !session[:registration][:user][:firstname]
						user = User.find_by(:email => params[:email])
						session[:registration][:user] = Hash.new
						session[:registration][:user][:id] = user ? user.id : nil
						session[:registration][:user][:firstname] = user ? (user.firstname || user.username) : nil
						session[:registration][:user][:lastname] = user ? user.lastname : nil
						session[:registration][:user][:username] = user ? user.username : nil
					end
					next_step = 'questions'
				end
			when 'primary'
				if params[:firstname].blank? || params[:lastname].blank?
					error = _'registration.register.no_name_error',"Oh, c'mon, please tell us your name. We promise not to share it with anyone, we just don't want to get you mixed up with someone else."
				end
				if (params[:is_volunteer] || 'false').to_sym != :true && (params[:is_participant] || 'false').to_sym != :true
					error ||= _'registration.register.no_role_error',"Please let us know if you're attending the conference or volunteering (or both)"
				end
				session[:registration][:user][:firstname] = params[:firstname]
				session[:registration][:user][:lastname] = params[:lastname]
				session[:registration][:is_volunteer] = (params[:is_volunteer] || 'false').to_sym == :true
				session[:registration][:is_participant] = (params[:is_participant] || 'false').to_sym == :true
				if !session[:registration][:user][:id]
					session[:registration][:user][:username] = !error && params[:username].blank? ? (params[:firstname] + ' ' + params[:lastname]) : params[:username]
				end

				if session[:registration][:is_volunteer]
					next_step = 'volunteer_questions'
				elsif session[:registration][:is_participant]
					next_step = 'questions'
				end
			when 'organizations'
				@registration = ConferenceRegistration.find(session[:registration][:registration_id])
				if (params[:org] && params[:org].length > 0) || params[:add_new_org]
					session[:registration][:organizations] = Array.new
					if params[:org]
						params[:org].each { |org| session[:registration][:organizations] << (org.is_a?(Array) ? org.first : org).to_i }
					end
					update_registration_data

					if params[:add_new_org]
						session[:registration][:new_organization] ||= Array.new
						session[:registration][:new_organization][0] ||= Hash.new
						session[:registration][:new_org_index] = 0
						if !session[:registration][:new_organization][0][:country]
							my_location = lookup_ip_location
							session[:registration][:new_organization][0][:country] = my_location.country_code
							session[:registration][:new_organization][0][:territory] = my_location.province_code
							session[:registration][:new_organization][0][:city] = my_location.city
						end
						next_step = 'new_organization'
					else
						if session[:registration][:is_workshop_host]
							next_step = 'new_workshop'
							session[:registration][:workshop] ||= Array.new
							session[:registration][:workshop][0] ||= Hash.new
							session[:registration][:workshop_index] = 0
						else
							complete_registration
							next_step = 'thanks'
						end
					end
				elsif params[:no_org]
					if !session[:registration][:is_workshop_host]
						next_step = 'new_workshop'
						session[:registration][:workshop] ||= Array.new
						session[:registration][:workshop][0] ||= Hash.new
						session[:registration][:workshop_index] = 0
					else
						complete_registration
						next_step = 'thanks'
					end
				else
					error = _'registration.register.no_organization_error',"Please select an organization or enter a new one"
				end
			when 'new_organization'
				if params[:organization_name].blank?
					error = _'register.new_organization.no_name_error',"Please tell us your organization's name"
				end
				if params[:organization_email].blank?
					error ||= _'register.new_organization.no_email_error',"Please tell us your organization's email address. We need it so that we can send out invitations for upcoming conferences. No spam, we promise, and you'll be able to edit your preferences before we start ending out email."
				elsif params[:organization_email].strip.casecmp(session[:registration][:email].strip) == 0
					error ||= _'register.new_organization.same_email_as_attendee_error',"This email needs to be different than your own personal email, we need to keep in touch with your organization even if you're gone in years to come."
				end
				if params[:organization_street].blank?
					error ||= _'register.new_organization.no_street_error','Please enter your organization\'s street address'
				end
				if params[:organization_city].blank?
					error ||= _'register.new_organization.no_city_error','Please enter your organization\'s city'
				end
				i = params[:new_org_index].to_i
				session[:registration][:new_organization][i][:country] = params[:organization_country]
				session[:registration][:new_organization][i][:territory] = params[:organization_territory]
				session[:registration][:new_organization][i][:city] = params[:organization_city]
				session[:registration][:new_organization][i][:street] = params[:organization_street]
				session[:registration][:new_organization][i][:info] = params[:organization_info]
				session[:registration][:new_organization][i][:email] = params[:organization_email]
				session[:registration][:new_organization][i][:name] = params[:organization_name]

				if params[:logo] && !session[:registration][:new_organization][i][:saved]
					begin
						if session[:registration][:new_organization][i][:logo]
							FileUtils.rm session[:registration][:new_organization][i][:logo]
						end
					rescue; end
					base_dir =  File.join("public", "registration_data")
					FileUtils.mkdir_p(base_dir) unless File.directory?(base_dir)
					hash_dir = rand_hash
					dir = File.join(base_dir, hash_dir)
					while File.directory?(dir)
						hash_dir = rand_hash
						dir = File.join(base_dir, hash_dir)
					end
					FileUtils.mkdir_p(dir)
					session[:registration][:new_organization][i][:logo] = File.join("registration_data", hash_dir, params[:logo].original_filename)
					FileUtils.cp params[:logo].tempfile.path, File.join("public", session[:registration][:new_organization][i][:logo])
				end
				update_registration_data
				if params[:add_another_org] && params[:add_another_org].to_sym == :true
					next_step = 'new_organization'
					if params[:previous]
						session[:registration][:new_org_index] = [0, i - 1].max
					elsif !error
						session[:registration][:new_org_index] = i + 1
						session[:registration][:new_organization][i + 1] ||= Hash.new
						if !session[:registration][:new_organization][i + 1][:country]
							session[:registration][:new_organization][i + 1][:country] = session[:registration][:new_organization][i][:country]
							session[:registration][:new_organization][i + 1][:territory] = session[:registration][:new_organization][i][:territory]
							session[:registration][:new_organization][i + 1][:city] = session[:registration][:new_organization][i][:city]
						end
					end
				else
					if session[:registration][:new_organization][i + 1]
						session[:registration][:new_organization] = session[:registration][:new_organization].first(i + 1)
					end
					if session[:registration][:is_workshop_host]
						next_step = 'new_workshop'
						session[:registration][:workshop] ||= Array.new
						session[:registration][:workshop][0] ||= Hash.new
						session[:registration][:workshop_index] = 0
					else
						complete_registration
						next_step = 'thanks'
					end
				end
			when 'questions'
				if params[:firstname].blank? || params[:lastname].blank?
					error = _'registration.register.no_name_error',"Oh, c'mon, please tell us your name. We promise not to share it with anyone, we just don't want to get you mixed up with someone else."
				end
				session[:registration][:user][:firstname] = params[:firstname]
				session[:registration][:user][:lastname] = params[:lastname]
				session[:registration][:is_volunteer] = false
				session[:registration][:is_participant] = true
				if !session[:registration][:user][:id]
					session[:registration][:user][:username] = !error && params[:username].blank? ? (params[:firstname] + ' ' + params[:lastname]) : params[:username]
				end

				session[:registration][:questions] = params[:questions].deep_symbolize_keys
				session[:registration][:is_workshop_host] = !params[:is_workshop_host].to_i.zero?
				next_step = 'organizations'
				if params[:cancel].blank?#params[:submit] || params[:next]
					if !session[:registration][:organizations]
						user = User.find_by(:email => session[:registration][:email])
						session[:registration][:organizations] = Array.new
						if user
							user.organizations.each { |org| session[:registration][:organizations] << org.id }
						end
					end
					create_registration
				end
			when 'volunteer_questions'
				session[:registration][:volunteer_questions] = params[:volunteer_questions].deep_symbolize_keys
				if session[:registration][:is_participant]
					next_step = 'questions'
				else
					create_registration
					next_step = 'thanks'
				end
			when 'new_workshop'
				i = params[:workshop_index].to_i
				session[:registration][:workshop][i][:title] = params[:workshop_title]
				session[:registration][:workshop][i][:info] = params[:workshop_info]
				session[:registration][:workshop][i][:stream] = params[:workshop_stream]
				session[:registration][:workshop][i][:presentation_style] = params[:workshop_presentation_style]
				session[:registration][:workshop][i][:notes] = params[:workshop_notes]

				if params[:workshop_title].blank?
					error = _'registration.register.no_workshop_title_error','Please give your workshop a title'
				end

				if params[:workshop_info].blank?
					error ||= _'registration.register.no_workshop_info_error','Please describe your workshop as best as you can to give other participants an idea of what to expect'
				end

				update_registration_data

				if params[:previous]
					session[:registration][:workshop_index] = [0, i - 1].max
				elsif params[:add_another_workshop]
					next_step = 'new_workshop'
					if !error
						session[:registration][:workshop] ||= Array.new
						session[:registration][:workshop][i + 1] ||= Hash.new
						session[:registration][:workshop_index] = i + 1
					end
				else
					if session[:registration][:workshop][i + 1]
						session[:registration][:workshop] = session[:registration][:workshop].first(i + 1)
					end
					next_step = 'thanks'
					complete_registration
				end
			when 'thanks'
				@registration = ConferenceRegistration.find(session[:registration][:registration_id])
				if @registration.is_confirmed.blank?
					send_confirmation
				end
				next_step = 'thanks'
			when 'cancel'
				if params[:yes]
					session.delete(:registration)
					next_step = 'cancelled'
				else
					return {error: false, next_step: session[:registration][:path].pop}
				end
			when 'already_registered'
				send_confirmation
				next_step = 'thanks'
			when 'paypal-confirmed'
				@registration = ConferenceRegistration.find(session[:registration][:registration_id])
				next_step = 'confirm_payment'
			when 'confirm_payment'
				@registration = ConferenceRegistration.find(session[:registration][:registration_id])
				if params[:confirm_payment]
					info = YAML.load(@registration.payment_info)
					amount = nil
					status = nil
					if is_test?
						status = info[:status]
						amount = info[:amount]
					else
						paypal = PayPal!.checkout!(info[:token], info[:payer_id], PayPalRequest(info[:amount]))
						status = paypal.payment_info.first.payment_status
						amount = paypal.payment_info.first.amount.total
					end
					if status == 'Completed'
						@registration.registration_fees_paid = amount
						@registration.save!
					end
				end
				next_step = 'thanks'
			when 'pay_now', 'payment-confirmed', 'paypal-cancelled'
				next_step = 'thanks'
		end
		session.delete(:registration_step)
		#if params[:previous]
		#	next_step = session[:registration][:path].pop
		#else
		if !params[:cancel] && error
			return {error: true, message: error, next_step: params['step']}
		end
		if session[:registration] && session[:registration][:path] && params['step']
			session[:registration][:path] << params['step']
		end
		#end
		{error: false, next_step: params[:cancel] ? 'cancel' : next_step}
	end

	def broadcast
		set_conference
		set_conference_registration
		raise ActiveRecord::PremissionDenied unless (current_user && @this_conference.host?(current_user))

		@subject = params[:subject]
		@content = params[:content]

		if request.post?
			if params[:button] == 'edit'
				@email_sent = :edit
			elsif params[:button] == 'test'
				@email_sent = :test
				UserMailer.broadcast(
					"#{request.protocol}#{request.host_with_port}",
					@subject,
					@content,
					current_user,
					@this_conference).deliver_now
			elsif params[:button] == 'preview'
				@email_sent = :preview
			elsif params[:button] == 'send'
				ConferenceRegistration.where(:conference_id => @this_conference.id).each do |r|
					if r.user_id
						UserMailer.broadcast("#{request.protocol}#{request.host_with_port}",
							@subject,
							@content,
							User.find(r.user_id),
							@this_conference).deliver_later
					end
				end
				@email_sent = :yes
			end
		end
	end

	def stats
		set_conference
		set_conference_registration
		raise ActiveRecord::PremissionDenied unless (current_user && @this_conference.host?(current_user))

		@registrations = ConferenceRegistration.where(:conference_id => @this_conference.id)

		@total_registrations = 0
		@donation_count = 0
		@total_donations = 0
		@housing = {}
		@bikes = {}
		@bike_count = 0
		@languages = {}
		@food = {}
		@allergies = []
		@other = []

		if request.format.xls?
			logger.info "Generating stats.xls"
			@excel_data = {
				:columns => [:name, :email, :city, :date, :languages, :arrival, :departure, :housing, :bike, :food, :allergies, :other, :fees_paid],
				:key => 'articles.conference_registration.headings',
				:data => []
			}
		end

		@registrations.each do |r|
			if r && r.is_attending
				begin
					@total_registrations += 1
					
					@donation_count += 1 if r.registration_fees_paid
					@total_donations += r.registration_fees_paid unless r.registration_fees_paid.blank?

					unless r.housing.blank?
						@housing[r.housing.to_sym] ||= 0
						@housing[r.housing.to_sym] += 1
					end

					unless r.bike.blank?
						@bikes[r.bike.to_sym] ||= 0
						@bikes[r.bike.to_sym] += 1
						@bike_count += 1 unless r.bike.to_sym == :none
					end

					unless r.food.blank?
						@food[r.food.to_sym] ||= 0
						@food[r.food.to_sym] += 1
					end

					@allergies << r.allergies unless r.allergies.blank?
					@other << r.other unless r.other.blank?

					JSON.parse(r.languages).each do |l|
						@languages[l.to_sym] ||= 0
						@languages[l.to_sym] += 1
					end unless r.languages.blank?

					if @excel_data
						user = r.user_id ? User.find(r.user_id) : nil
						@excel_data[:data] << {
							:name => (user ? user.firstname : nil) || '',
							:email => (user ? user.email : nil) || '',
							:date => r.created_at ? r.created_at.strftime("%F %T") : '',
							:city => r.city || '',
							:languages => ((JSON.parse(r.languages || '[]').map { |x| I18n.t"languages.#{x}" }).join(', ').to_s),
							:arrival => r.arrival ? r.arrival.strftime("%F %T") : '',
							:departure => r.departure ? r.departure.strftime("%F %T") : '',
							:housing => (I18n.t"articles.conference_registration.questions.housing.#{r.housing || 'none'}"),
							:bike => (I18n.t"articles.conference_registration.questions.bike.#{r.bike || 'none'}"),
							:food => (I18n.t"articles.conference_registration.questions.food.#{r.food || 'meat'}"),
							:fees_paid => (r.registration_fees_paid || 0.0),
							:allergies => r.allergies || '',
							:other => r.other || ''
						}
					end
				rescue => error
					logger.info "Error adding row to stats.xls: #{error.message}"
					logger.info error.backtrace.join("\n\t")
				end
			end
		end

		if ENV["RAILS_ENV"] == 'test' && request.format.xls?
			logger.info "Rendering stats.xls as HTML"
			request.format = :html
			respond_to do |format|
				format.html { render :file => 'application/excel.xls.haml', :formats => [:xls] }
			end
			return
		end

		logger.info "Rendering stats.xls" if request.format.xls?

		respond_to do |format|
			format.html
			format.text { render :text => content }
			format.xls { render 'application/excel' }
		end

	end

	def register
		is_post = request.post? || session[:registration_step]
		set_conference

		#if !@this_conference.registration_open
		#	do_404
		#	return
		#end

		set_conference_registration

		@register_template = nil

		if logged_in?
			unless @this_conference.registration_open || @registration
				do_404
				return
			end
			# if the user is logged in start them off on the policy
			#  page, unless they have already begun registration then
			#  start them off with questions
			@register_template = @registration ? (@registration.registration_fees_paid ? :done : :payment) : :policy

			@name = current_user.firstname
			# we should phase out last names
			@name += " #{current_user.lastname}" if current_user.lastname

			@is_host = @this_conference.host? current_user
		end

		# process data from the last view
		case (params[:button] || '').to_sym
		when :confirm_email
			@register_template = :email_sent if is_post
		when :policy
			@register_template = :questions if is_post
		when :save
			if is_post
				if (new_registration = (!@registration))
					@registration = ConferenceRegistration.new
				end

				@registration.conference_id = @this_conference.id
				@registration.user_id = current_user.id
				@registration.is_attending = 'yes'
				@registration.is_confirmed = true
				@registration.city = params[:location]
				@registration.arrival = params[:arrival]
				@registration.languages = params[:languages].keys.to_json
				@registration.departure = params[:departure]
				@registration.housing = params[:housing]
				@registration.bike = params[:bike]
				@registration.food = params[:food]
				@registration.allergies = params[:allergies]
				@registration.other = params[:other]
				@registration.save

				current_user.firstname = params[:name].squish
				current_user.lastname = nil
				current_user.save

				if new_registration
					UserMailer.send_mail :registration_confirmation do
						{
							:args => @registration
						}
					end
				end

				@register_template = @registration.registration_fees_paid ? :done : :payment
			end
		when :payment
			if is_post && @registration
				amount = params[:amount].to_f

				if amount > 0
					@registration.payment_confirmation_token = ENV['RAILS_ENV'] == 'test' ? 'token' : Digest::SHA256.hexdigest(rand(Time.now.to_f * 1000000).to_i.to_s)
					@registration.save
					
					host = "#{request.protocol}#{request.host_with_port}"
					response = PayPal!.setup(
						PayPalRequest(amount),
						register_paypal_confirm_url(@this_conference.slug, :paypal_confirm, @registration.payment_confirmation_token),
						register_paypal_confirm_url(@this_conference.slug, :paypal_cancel, @registration.payment_confirmation_token)
					)
					if ENV['RAILS_ENV'] != 'test'
						redirect_to response.redirect_uri
					end
					return
				end
				@register_template = :done
			end
		when :paypal_confirm
			if @registration && @registration.payment_confirmation_token == params[:confirmation_token]

				if ENV['RAILS_ENV'] == 'test'
					@amount = YAML.load(@registration.payment_info)[:amount]
				else
					@amount = PayPal!.details(params[:token]).amount.total
					# testing this does't work in test but it works in devo and prod
					@registration.payment_info = {:payer_id => params[:PayerID], :token => params[:token], :amount => @amount}.to_yaml
				end

				@amount = (@amount * 100).to_i.to_s.gsub(/^(.*)(\d\d)$/, '\1.\2')

				@registration.save!
				@register_template = :paypal_confirm
			end
		when :paypal_confirmed
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
				@registration.registration_fees_paid = @amount
				@registration.save!
				@register_template = :done
			else
				@register_template = :payment
			end
		when :paypal_cancel
			if @registration
				@registration.payment_confirmation_token = nil
				@registration.save
				@register_template = :payment
			end
		when :register
			@register_template = :questions
		end

		if @register_template == :payment && !@this_conference.paypal_username
			@register_template = :done
		end

		# don't let the user edit registration if registration is closed
		if !@conference.registration_open && @register_template == :questions
			@register_template = :done
		end

		# prepare data for the next view
		case @register_template
		when :questions
			@registration ||= ConferenceRegistration.new(
					:conference_id => @this_conference.id,
					:user_id => current_user.id,
					:is_attending => 'yes',
					:is_confirmed => true,
					:city => view_context.location(view_context.lookup_ip_location),
					:arrival => @this_conference.start_date,
					:departure => @this_conference.end_date,
					:housing => nil,
					:bike => nil,
					:other => ''
				);
			@languages = [I18n.locale.to_sym]

			if @registration.languages
				@languages = JSON.parse(@registration.languages).map &:to_sym
			end
		when :workshops
			@my_workshops = [1,2,3,4].map { |i|
				{
					:title => (Forgery::LoremIpsum.sentence({:random => true}).gsub(/\.$/, '').titlecase),
					:info => (Forgery::LoremIpsum.sentences(rand(1...5), {:random => true}))
				}
			}
		when :done
			@amount = ((@registration.registration_fees_paid || 0) * 100).to_i.to_s.gsub(/^(.*)(\d\d)$/, '\1.\2')
		end

	end

	def registrations
		registrations = ConferenceRegistration.where(:conference_id => @conference.id)
		@registrations = registrations
	end

	def register_confirm
		set_conference
		@conference_registration = ConferenceRegistration.find_by(confirmation_token: params[:confirmation_token])
		if !@conference_registration.nil? && @conference_registration.conference_id == @conference.id && !@conference_registration.complete
			@conference_registration.is_confirmed = true
			@conference_registration.save!
			session[:registration] = YAML.load(@conference_registration.data)
			session[:registration][:path] = Array.new
			session[:registration][:registration_id] = @conference_registration.id
			session[:registration_step] = 'confirm'
			redirect_to action: 'register'
		else
			do_404
		end
	end

	def register_pay_registration
		set_conference
		@conference_registration = ConferenceRegistration.find_by(confirmation_token: params[:confirmation_token])
		host = "#{request.protocol}#{request.host_with_port}"
		if !@conference_registration.nil? && @conference_registration.conference_id == @conference.id && @conference_registration.complete
			amount = (params[:auto_payment_amount] || params[:payment_amount]).to_f
			if amount > 0
				response = PayPal!.setup(
					PayPalRequest(amount),
					host + (@conference.url + "/register/paypal-confirm/#{@conference_registration.payment_confirmation_token}/").gsub(/\/\/+/, '/'),
					host + (@conference.url + "/register/paypal-cancel/#{@conference_registration.confirmation_token}/").gsub(/\/\/+/, '/')
				)
				redirect_to response.redirect_uri
			else
				session[:registration] = YAML.load(@conference_registration.data)
				session[:registration][:registration_id] = @conference_registration.id
				session[:registration][:path] = Array.new
				session[:registration_step] = 'pay_now'
				redirect_to action: 'register'
			end
		else
			do_404
		end
	end

	# def register_paypal_confirm
	# 	set_conference
	# 	@conference_registration = ConferenceRegistration.find_by(payment_confirmation_token: params[:confirmation_token])
	# 	if !@conference_registration.nil? && @conference_registration.conference_id == @conference.id && @conference_registration.complete && @conference_registration.registration_fees_paid.nil?
	# 		if !is_test?
	# 			#@conference_registration.payment_info = {:payer_id => '1234', :token => '5678', :amount => '0.00'}.to_yaml
	# 		#else
	# 			@conference_registration.payment_info = {:payer_id => params[:PayerID], :token => params[:token], :amount => PayPal!.details(params[:token]).amount.total}.to_yaml
	# 			@conference_registration.save!
	# 		end
	# 		session[:registration] = YAML.load(@conference_registration.data)
	# 		session[:registration][:registration_id] = @conference_registration.id
	# 		session[:registration][:path] = Array.new
	# 		session[:registration_step] = 'paypal-confirmed'
	# 		redirect_to action: 'register'
	# 	else
	# 		do_404
	# 	end
	# end

	def register_paypal_cancel
		set_conference
		@conference_registration = ConferenceRegistration.find_by(confirmation_token: params[:confirmation_token])
		if !@conference_registration.nil? && @conference_registration.conference_id == @conference.id && @conference_registration.complete && @conference_registration.payment_info.nil?
			session[:registration] = YAML.load(@conference_registration.data)
			redirect_to action: 'register'
		end
	end

	def register_step
		set_conference
		data = params
		if params[:conference][:user][:email]
			user = User.find_by(:email => params[:conference][:user][:email])
			data[:conference][:user][:username] = user.username
		end
		render json: data
	end

	def add_field
		set_conference
		field = RegistrationFormField.find(params[:field])
		@conference.registration_form_fields << field

		@registration_form_fields = RegistrationFormField.where(["id NOT IN (?)", @conference.registration_form_fields.map(&:id)])

		form = render_to_string :partial => 'registration_form_fields/conference_form'
		list = render_to_string :partial => 'registration_form_fields/list'
		render json: {form: form, list: list}
	end

	def remove_field
		set_conference
		field = RegistrationFormField.find(params[:field])
		@conference.registration_form_fields.delete(field)

		@registration_form_fields = RegistrationFormField.where(["id NOT IN (?)", @conference.registration_form_fields.map(&:id)])

		form = render_to_string :partial => 'registration_form_fields/conference_form'
		list = render_to_string :partial => 'registration_form_fields/list'
		render json: {form: form, list: list}
	end

	def reorder
		set_conference
		params[:registration_form_field_id].each do |key, value|
			update_field_position(value.to_i, params[:position][key].to_i)
		end
		render json: [].to_json
	end

	def form
		set_conference
	end

	def workshops
		set_conference
		set_conference_registration
		@workshops = Workshop.where(:conference_id => @this_conference.id)
		@my_workshops = Workshop.joins(:workshop_facilitators).where(:workshop_facilitators => {:user_id => current_user.id}, :conference_id => @this_conference.id)#, :workshop_facilitator => current_user.id)
		render 'workshops/index'
	end

	def view_workshop
		set_conference
		set_conference_registration
		@workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
		do_404 unless @workshop
		render 'workshops/show'
	end

	def create_workshop
		set_conference
		set_conference_registration
		@languages = []
		@needs = []
		render 'workshops/new'
	end

	def edit_workshop
		set_conference
		set_conference_registration
		@workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
		do_404 unless @workshop
		@can_edit = @workshop.can_edit?(current_user)
		do_403 unless @can_edit || @workshop.can_translate?(current_user, I18n.locale)
		@title = @workshop.title
		@info = @workshop.info
		@needs = JSON.parse(@workshop.needs || '[]').map &:to_sym
		@languages = JSON.parse(@workshop.languages || '[]').map &:to_sym
		@space = @workshop.space.to_sym if @workshop.space
		@theme = @workshop.theme.to_sym if @workshop.theme
		@notes = @workshop.notes
		render 'workshops/new'
	end

	def delete_workshop
		set_conference
		set_conference_registration
		@workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)

		if !@workshop
			do_404
			return
		end

		if !@workshop.can_delete?(current_user)
			do_403
			return
		end

		if request.post?
			if params[:button] == 'confirm'
				if @workshop
					@workshop.workshop_facilitators.destroy_all
					@workshop.destroy
				end

				redirect_to workshops_url
				return
			end
			redirect_to edit_workshop_url(@this_conference.slug, @workshop.id)
			return
		end

		render 'workshops/delete'
	end
	
	def save_workshop
		set_conference
		set_conference_registration

		if params[:workshop_id]
			workshop = Workshop.find(params[:workshop_id])
			do_404 unless workshop
		else
			workshop = Workshop.new(:conference_id => @this_conference.id)
			workshop.workshop_facilitators = [WorkshopFacilitator.new(:user_id => current_user.id, :role => :creator)]
		end

		can_edit = workshop.can_edit?(current_user)
		do_403 unless can_edit || workshop.can_translate?(current_user, I18n.locale)

		workshop.title = params[:title]
		workshop.info  = params[:info]

		if can_edit
			# dont allow translators to edit these fields
			workshop.languages = (params[:languages] || {}).keys.to_json
			workshop.needs     = (params[:needs] || {}).keys.to_json
			workshop.theme     = params[:theme] == 'other' ? params[:other_theme] : params[:theme]
			workshop.space     = params[:space]
			workshop.notes     = params[:notes]
		end

		workshop.save
		redirect_to view_workshop_url(@this_conference.slug, workshop.id)
	end

	def toggle_workshop_interest
		set_conference
		set_conference_registration
		workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
		do_404 unless workshop

		# save the current state
		interested = workshop.interested? current_user
		# remove all associated fields
		WorkshopInterest.delete_all(:workshop_id => workshop.id, :user_id => current_user.id)

		# creat the new interest row if we weren't interested before
		WorkshopInterest.create(:workshop_id => workshop.id, :user_id => current_user.id) unless interested

		# go back to the workshop
		redirect_to view_workshop_url(@this_conference.slug, workshop.id)
	end

	def facilitate_workshop
		set_conference
		set_conference_registration
		@workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
		do_404 unless @workshop
		do_403 if @workshop.facilitator?(current_user) || !current_user

		render 'workshops/facilitate'
	end

	def facilitate_request
		set_conference
		set_conference_registration
		workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
		do_404 unless workshop
		do_403 if workshop.facilitator?(current_user) || !current_user

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
		set_conference_registration
		@workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
		do_404 unless @workshop
		do_403 unless @workshop.requested_collaborator?(current_user)

		render 'workshops/facilitate_request_sent'
	end

	def approve_facilitate_request
		set_conference
		set_conference_registration
		workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
		do_404 unless workshop && current_user
		
		user_id = params[:user_id].to_i
		action = params[:approve_or_deny].to_sym
		user = User.find(user_id)
		if action == :approve
			if current_user && workshop.active_facilitator?(current_user) && workshop.requested_collaborator?(User.find(user_id))
				f = WorkshopFacilitator.find_by_workshop_id_and_user_id(
						workshop.id, user_id)
				f.role = :collaborator
				f.save
				UserMailer.send_mail :workshop_facilitator_request_approved do
					{
						:args => [ workshop, user ]
					}
				end
				return redirect_to view_workshop_url(@this_conference.slug, workshop.id)		
			end
		elsif action == :deny
			if current_user && workshop.active_facilitator?(current_user) && workshop.requested_collaborator?(User.find(user_id))
				WorkshopFacilitator.delete_all(
					:workshop_id => workshop.id,
					:user_id => user_id)
				UserMailer.send_mail :workshop_facilitator_request_denied do
					{
						:args => [ workshop, user ]
					}
				end
				return redirect_to view_workshop_url(@this_conference.slug, workshop.id)		
			end
		elsif action == :remove
			if current_user && current_user.id == user_id
				unless workshop.creator?(user)
					WorkshopFacilitator.delete_all(
						:workshop_id => workshop.id,
						:user_id => user_id)
				end
				return redirect_to view_workshop_url(@this_conference.slug, workshop.id)
			end
		end

		do_403
	end

	def add_workshop_facilitator
		user = User.find_by_email(params[:email]) || User.create(email: params[:email])

		set_conference
		set_conference_registration
		workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)

		do_404 unless workshop && current_user

		unless workshop.facilitator?(user)
			WorkshopFacilitator.create(user_id: user.id, workshop_id: workshop.id, role: :collaborator)
			
			UserMailer.send_mail :workshop_facilitator_request_approved do
				{
					:args => [ workshop, user ]
				}
			end
		end

		return redirect_to view_workshop_url(@this_conference.slug, params[:workshop_id])
	end

	def schedule
		set_conference
		do_404 unless @this_conference.workshop_schedule_published || @this_conference.host?(current_user)
		
		@events = Event.where(:conference_id => @this_conference.id)
		@locations = EventLocation.where(:conference_id => @this_conference.id)

		render 'schedule/show'
	end

	def edit_schedule
		set_conference
		set_conference_registration
		do_404 unless @this_conference.host?(current_user)
		
		@workshops = Workshop.where(:conference_id => @this_conference.id)
		@events = Event.where(:conference_id => @this_conference.id)
		if session[:workshops]
			(0...@workshops.count).each do |i|
				id = @workshops[i].id
				w = session[:workshops][id.to_s]
				if w
					@workshops[i].start_time = w[:start_time]
					@workshops[i].end_time = w[:end_time]
					@workshops[i].event_location_id = w[:event_location_id]
				end
			end
		end
		if session[:events]
			(0...@events.count).each do |i|
				id = @events[i].id
				w = session[:events][id.to_s]
				if w
					@events[i].start_time = w[:start_time]
					@events[i].end_time = w[:end_time]
					@events[i].event_location_id = w[:event_location_id]
				end
			end
		end
		@locations = EventLocation.where(:conference_id => @this_conference.id)
		@location_hash = Hash.new
		@locations.each do |l|
			@location_hash[l.id.to_s] = l
		end

		@days = Array.new
		start_day = @this_conference.start_date.strftime('%u').to_i
		end_day = start_day + ((@this_conference.end_date - @this_conference.start_date) / 86400)

		(start_day..end_day).each do |i|
			@days << [(@this_conference.start_date + (i - start_day).days).strftime('%a'), ((i + 1) - start_day)]
		end

		@hours = Array.new
		(0..48).each do |i|
			hour = (Date.today + (i / 2.0).hours).strftime('%R')
			@hours << hour
		end

		@event_durations = [['30 mins', 30], ['1 hour', 60], ['1.5 hours', 90], ['2 hours', 120], ['2.5 hours', 150]]
		@workshop_durations = [['1 hour', 60], ['1.5 hours', 90], ['2 hours', 120]]

		schedule_data = get_schedule_data
		@schedule = schedule_data[:schedule]
		@errors = schedule_data[:errors]
		@warnings = schedule_data[:warnings]
		@conflict_score = schedule_data[:conflict_score]
		@error_count = schedule_data[:error_count]
		if session[:day_parts]
			@day_parts = JSON.parse(session[:day_parts])
		elsif @this_conference.day_parts
			@day_parts = JSON.parse(@this_conference.day_parts)
		else
			@day_parts = {:morning => 0, :afternoon => 13, :evening => 18}
		end
		@saved = session[:workshops].nil?

		render 'schedule/edit'
	end

	def save_schedule
		set_conference
		do_404 unless @this_conference.host?(current_user)

		@days = Array.new
		start_day = @this_conference.start_date.strftime('%u').to_i
		end_day = start_day + ((@this_conference.end_date - @this_conference.start_date) / 86400)

		(start_day..end_day).each do |i|
			@days << [(@this_conference.start_date + (i - start_day).days).strftime('%a'), i]
		end

		@workshops = Workshop.where(:conference_id => @this_conference.id)
		@events = Event.where(:conference_id => @this_conference.id)
		@locations = EventLocation.where(:conference_id => @this_conference.id)

		do_save = (params[:button] == 'save' || params[:button] == 'publish')
		session[:workshops] = do_save ? nil : Hash.new
		session[:events] = do_save ? nil : Hash.new
		session[:day_parts] = do_save ? nil : Hash.new

		(0...@workshops.count).each do |i|
			id = @workshops[i].id.to_s
			if params[:workshop_day][id].present? && params[:workshop_hour][id].present? && params[:workshop_duration][id].present?
				date = @this_conference.start_date + (params[:workshop_day][id].to_i - 1).days
				h = params[:workshop_hour][id].split(':')
				date = date.change({hour: h.first, minute: h.last})
				@workshops[i].start_time = date
				@workshops[i].end_time = date + (params[:workshop_duration][id].to_i).minutes
			else
				@workshops[i].start_time = nil
				@workshops[i].end_time = nil
			end
			@workshops[i].event_location_id = params[:workshop_location][id]
			if do_save
				@workshops[i].save
			else
				session[:workshops][id] = {
					:start_time => @workshops[i].start_time,
					:end_time => @workshops[i].end_time,
					:end_time => @workshops[i].end_time,
					:event_location_id => @workshops[i].event_location_id
				}
			end
		end

		(0...@events.count).each do |i|
			id = @events[i].id.to_s
			if params[:event_day][id].present? && params[:event_hour][id].present? && params[:event_duration][id].present?
				date = @this_conference.start_date + (params[:event_day][id].to_i - 1).days
				h = params[:event_hour][id].split(':')
				date = date.change({hour: h.first, minute: h.last})
				@events[i].start_time = date
				@events[i].end_time = date + (params[:event_duration][id].to_i).minutes
			else
				@events[i].start_time = nil
				@events[i].end_time = nil
			end
			@events[i].event_location_id = params[:event_location][id]
			if do_save
				@events[i].save
			else
				session[:events][id] = {
					:start_time => @events[i].start_time,
					:end_time => @events[i].end_time,
					:end_time => @events[i].end_time,
					:event_location_id => @events[i].event_location_id
				}
			end
		end

		if params[:day_parts]
			day_parts = {:morning => 0}
			params[:day_parts].each do |part, h|
				h = h.split(':')
				day_parts[part.to_sym] = h[0].to_f + (h[1].to_i > 0 ? 0.5 : 0)
			end
			if do_save
				@this_conference.day_parts = day_parts.to_json
			else
				session[:day_parts] = day_parts.to_json
			end
		end

		save_conference = do_save

		if params[:button] == 'publish'
			@this_conference.workshop_schedule_published = true
			save_conference = true
		elsif params[:button] == 'unpublish'
			@this_conference.workshop_schedule_published = false
			save_conference = true
		end

		if save_conference
			@this_conference.save
		end

		redirect_to edit_schedule_url(@this_conference.slug)
	end

	def add_event
		set_conference
		set_conference_registration
		do_404 unless @this_conference.host?(current_user)
		
		render 'events/edit'
	end

	def edit_event
		set_conference
		set_conference_registration
		do_404 unless @this_conference.host?(current_user)

		@event = Event.find(params[:id])
		do_403 unless @event.conference_id == @this_conference.id

		render 'events/edit'
	end

	def save_event
		set_conference
		do_404 unless @this_conference.host?(current_user)


		if params[:event_id]
			event = Event.find(params[:event_id])
			do_403 unless event.conference_id == @this_conference.id
		else
			event = Event.new(:conference_id => @this_conference.id)
		end

		event.title = params[:title]
		event.info = params[:info]
		event.event_type = params[:event_type]

		event.save

		return redirect_to schedule_url(@this_conference.slug)
	end

	def add_location
		set_conference
		set_conference_registration
		do_404 unless @this_conference.host?(current_user)
		
		render 'event_locations/edit'
	end

	def edit_location
		set_conference
		set_conference_registration
		do_404 unless @this_conference.host?(current_user)

		@location = EventLocation.find(params[:id])
		do_403 unless @location.conference_id == @this_conference.id

		@amenities = JSON.parse(@location.amenities || '[]').map &:to_sym

		render 'event_locations/edit'
	end

	def save_location
		set_conference
		do_404 unless @this_conference.host?(current_user)


		if params[:location_id]
			location = EventLocation.find(params[:location_id])
			do_403 unless location.conference_id == @this_conference.id
		else
			location = EventLocation.new(:conference_id => @this_conference.id)
		end

		location.title = params[:title]
		location.address = params[:address]
		location.amenities = (params[:needs] || {}).keys.to_json

		location.save

		return redirect_to schedule_url(@this_conference.slug)
	end

	# DELETE /conferences/1
	#def destroy
	#	@conference.destroy
	#	redirect_to conferences_url, notice: 'Conference was successfully destroyed.'
	#end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_conference
			@this_conference = Conference.find_by!(slug: params[:conference_slug] || params[:slug])
		end

		def set_conference_registration
			@registration = logged_in? ? ConferenceRegistration.find_by(:user_id => current_user.id, :conference_id => @this_conference.id) : nil
			@is_host = @this_conference.host?(current_user)
			if @registration || @is_host
				@submenu = {
					register_path(@this_conference.slug) => 'registration.Registration',
					workshops_path(@this_conference.slug) => 'registration.Workshops'
				}
				@submenu[schedule_path(@this_conference.slug)] = 'registration.Schedule' if @this_conference.workshop_schedule_published || @is_host
				if @is_host
					@submenu[edit_conference_path(@this_conference.slug)] = 'registration.Edit'
					@submenu[stats_path(@this_conference.slug)] = 'registration.Stats'
					@submenu[broadcast_path(@this_conference.slug)] = 'registration.Broadcast'
				end
			end
		end

		# Only allow a trusted parameter "white list" through.
		def conference_params
			params.require(:conference).permit(:title, :slug, :start_date, :end_date, :info, :poster, :cover, :workshop_schedule_published, :registration_open, :meals_provided, :meal_info, :travel_info, :conference_type_id, conference_types: [:id])
		end

		def update_field_position(field_id, position)
			#ConferenceRegistrationFormField.where(:conference_id => @conference.id, :registration_form_field_id => field_id).update_all(:position => position)
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
					:is_attending		=> 'yes',
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

	def PayPal!
		Paypal::Express::Request.new(
			:username   => @this_conference.paypal_username,
			:password   => @this_conference.paypal_password,
			:signature  => @this_conference.paypal_signature
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
				LOGOIMG: "https://cdn.bikebike.org/assets/bblogo-paypal.png"
			}
		)
	end
end
