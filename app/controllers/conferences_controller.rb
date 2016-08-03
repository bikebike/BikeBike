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
	# def index
	# 	@conference_type = nil
	# 	if params['conference_type']
	# 		@conference_type = ConferenceType.find_by!(:slug => params['conference_type'])
	# 		@conferences = Conference.where(:conference_type_id => @conference_type.id)
	# 	else
	# 		@conferences = Conference.all
	# 	end
	# end

	# # GET /conferences/1
	# def show
	# end

	# # GET /conferences/new
	# def new
	# 	@conference = Conference.new
	# 	@conference.build_conference_type
	# end

	# # GET /conferences/1/edit
	# def edit
	# 	set_conference
	# 	set_conference_registration
	# 	raise ActiveRecord::PremissionDenied unless (current_user && @this_conference.host?(current_user))
	# end

	# # PATCH/PUT /conferences/1
	# def save
	# 	set_conference
	# 	set_conference_registration
	# 	raise ActiveRecord::PremissionDenied unless (current_user && @this_conference.host?(current_user))

	# 	@this_conference.info = params[:info]
	# 	@this_conference.save

	# 	redirect_to edit_conference_path(@this_conference)
	# end

	# def hosts
	# 	set_conference
	# 	@conference.conference_host_organizations.build
	# end

	# def nonhosts
	# 	set_conference
	# 	@available_orgs = Organization.where(["id NOT IN (?)", @conference.organizations.map(&:id) + (params[:added] || [])])
	# 	html = '<h2>Select an Organization</h2><div id="select-organization-list">'
	# 	@available_orgs.each do |organization|
	# 		html += '<a href="#" class="organization-preview" data-id="' + organization.id.to_s + '"><img src="' + (organization.avatar.url :thumb) + '" /><div class="username">' + (organization.name) + '</div></a>'
	# 	end
	# 	render :text => (html + '</div>')
	# end

	# def registration
	# 	set_conference
	# 	@sub_action = 'registration' + (params[:sub_action] ? '_' + params[:sub_action] : '')
	# 	if params[:sub_action] == 'form'
	# 		@registration_form_field = RegistrationFormField.new
	# 		@registration_form_fields = RegistrationFormField.where(["id NOT IN (?)", @conference.registration_form_fields.map(&:id)])
	# 	end
	# end

	# def register_submit
	# 	next_step = nil
	# 	if !session[:registration]
	# 		session[:registration] = Hash.new
	# 		session[:registration][:path] = Array.new
	# 	end

	# 	case session[:registration_step] || params['step']
	# 		when 'confirm'
	# 			if session[:registration][:is_participant]
	# 				@registration = ConferenceRegistration.find(session[:registration][:registration_id])
	# 				if @registration.completed
	# 					complete_registration
	# 					next_step = 'thanks'
	# 				else
	# 					next_step = 'organizations'
	# 				end
	# 			else
	# 				complete_registration
	# 				next_step = 'thanks'
	# 			end
	# 		when 'register'
	# 			session[:registration][:email] = params[:email]
	# 			registration = ConferenceRegistration.find_by(:email => params[:email])
	# 			if !registration.nil?
	# 				session[:registration] = YAML.load(registration.data)
	# 				session[:registration][:registration_id] = registration.id
	# 				next_step = (registration.completed.blank? && registration.is_participant.present? ? 'organizations' : 'thanks')
	# 			else
	# 				if !session[:registration][:user] || !session[:registration][:user][:firstname]
	# 					user = User.find_by(:email => params[:email])
	# 					session[:registration][:user] = Hash.new
	# 					session[:registration][:user][:id] = user ? user.id : nil
	# 					session[:registration][:user][:firstname] = user ? (user.firstname || user.username) : nil
	# 					session[:registration][:user][:lastname] = user ? user.lastname : nil
	# 					session[:registration][:user][:username] = user ? user.username : nil
	# 				end
	# 				next_step = 'questions'
	# 			end
	# 		when 'primary'
	# 			if params[:firstname].blank? || params[:lastname].blank?
	# 				error = _'registration.register.no_name_error',"Oh, c'mon, please tell us your name. We promise not to share it with anyone, we just don't want to get you mixed up with someone else."
	# 			end
	# 			if (params[:is_volunteer] || 'false').to_sym != :true && (params[:is_participant] || 'false').to_sym != :true
	# 				error ||= _'registration.register.no_role_error',"Please let us know if you're attending the conference or volunteering (or both)"
	# 			end
	# 			session[:registration][:user][:firstname] = params[:firstname]
	# 			session[:registration][:user][:lastname] = params[:lastname]
	# 			session[:registration][:is_volunteer] = (params[:is_volunteer] || 'false').to_sym == :true
	# 			session[:registration][:is_participant] = (params[:is_participant] || 'false').to_sym == :true
	# 			if !session[:registration][:user][:id]
	# 				session[:registration][:user][:username] = !error && params[:username].blank? ? (params[:firstname] + ' ' + params[:lastname]) : params[:username]
	# 			end

	# 			if session[:registration][:is_volunteer]
	# 				next_step = 'volunteer_questions'
	# 			elsif session[:registration][:is_participant]
	# 				next_step = 'questions'
	# 			end
	# 		when 'organizations'
	# 			@registration = ConferenceRegistration.find(session[:registration][:registration_id])
	# 			if (params[:org] && params[:org].length > 0) || params[:add_new_org]
	# 				session[:registration][:organizations] = Array.new
	# 				if params[:org]
	# 					params[:org].each { |org| session[:registration][:organizations] << (org.is_a?(Array) ? org.first : org).to_i }
	# 				end
	# 				update_registration_data

	# 				if params[:add_new_org]
	# 					session[:registration][:new_organization] ||= Array.new
	# 					session[:registration][:new_organization][0] ||= Hash.new
	# 					session[:registration][:new_org_index] = 0
	# 					if !session[:registration][:new_organization][0][:country]
	# 						my_location = lookup_ip_location
	# 						session[:registration][:new_organization][0][:country] = my_location.country_code
	# 						session[:registration][:new_organization][0][:territory] = my_location.province_code
	# 						session[:registration][:new_organization][0][:city] = my_location.city
	# 					end
	# 					next_step = 'new_organization'
	# 				else
	# 					if session[:registration][:is_workshop_host]
	# 						next_step = 'new_workshop'
	# 						session[:registration][:workshop] ||= Array.new
	# 						session[:registration][:workshop][0] ||= Hash.new
	# 						session[:registration][:workshop_index] = 0
	# 					else
	# 						complete_registration
	# 						next_step = 'thanks'
	# 					end
	# 				end
	# 			elsif params[:no_org]
	# 				if !session[:registration][:is_workshop_host]
	# 					next_step = 'new_workshop'
	# 					session[:registration][:workshop] ||= Array.new
	# 					session[:registration][:workshop][0] ||= Hash.new
	# 					session[:registration][:workshop_index] = 0
	# 				else
	# 					complete_registration
	# 					next_step = 'thanks'
	# 				end
	# 			else
	# 				error = _'registration.register.no_organization_error',"Please select an organization or enter a new one"
	# 			end
	# 		when 'new_organization'
	# 			if params[:organization_name].blank?
	# 				error = _'register.new_organization.no_name_error',"Please tell us your organization's name"
	# 			end
	# 			if params[:organization_email].blank?
	# 				error ||= _'register.new_organization.no_email_error',"Please tell us your organization's email address. We need it so that we can send out invitations for upcoming conferences. No spam, we promise, and you'll be able to edit your preferences before we start ending out email."
	# 			elsif params[:organization_email].strip.casecmp(session[:registration][:email].strip) == 0
	# 				error ||= _'register.new_organization.same_email_as_attendee_error',"This email needs to be different than your own personal email, we need to keep in touch with your organization even if you're gone in years to come."
	# 			end
	# 			if params[:organization_street].blank?
	# 				error ||= _'register.new_organization.no_street_error','Please enter your organization\'s street address'
	# 			end
	# 			if params[:organization_city].blank?
	# 				error ||= _'register.new_organization.no_city_error','Please enter your organization\'s city'
	# 			end
	# 			i = params[:new_org_index].to_i
	# 			session[:registration][:new_organization][i][:country] = params[:organization_country]
	# 			session[:registration][:new_organization][i][:territory] = params[:organization_territory]
	# 			session[:registration][:new_organization][i][:city] = params[:organization_city]
	# 			session[:registration][:new_organization][i][:street] = params[:organization_street]
	# 			session[:registration][:new_organization][i][:info] = params[:organization_info]
	# 			session[:registration][:new_organization][i][:email] = params[:organization_email]
	# 			session[:registration][:new_organization][i][:name] = params[:organization_name]

	# 			if params[:logo] && !session[:registration][:new_organization][i][:saved]
	# 				begin
	# 					if session[:registration][:new_organization][i][:logo]
	# 						FileUtils.rm session[:registration][:new_organization][i][:logo]
	# 					end
	# 				rescue; end
	# 				base_dir =  File.join("public", "registration_data")
	# 				FileUtils.mkdir_p(base_dir) unless File.directory?(base_dir)
	# 				hash_dir = rand_hash
	# 				dir = File.join(base_dir, hash_dir)
	# 				while File.directory?(dir)
	# 					hash_dir = rand_hash
	# 					dir = File.join(base_dir, hash_dir)
	# 				end
	# 				FileUtils.mkdir_p(dir)
	# 				session[:registration][:new_organization][i][:logo] = File.join("registration_data", hash_dir, params[:logo].original_filename)
	# 				FileUtils.cp params[:logo].tempfile.path, File.join("public", session[:registration][:new_organization][i][:logo])
	# 			end
	# 			update_registration_data
	# 			if params[:add_another_org] && params[:add_another_org].to_sym == :true
	# 				next_step = 'new_organization'
	# 				if params[:previous]
	# 					session[:registration][:new_org_index] = [0, i - 1].max
	# 				elsif !error
	# 					session[:registration][:new_org_index] = i + 1
	# 					session[:registration][:new_organization][i + 1] ||= Hash.new
	# 					if !session[:registration][:new_organization][i + 1][:country]
	# 						session[:registration][:new_organization][i + 1][:country] = session[:registration][:new_organization][i][:country]
	# 						session[:registration][:new_organization][i + 1][:territory] = session[:registration][:new_organization][i][:territory]
	# 						session[:registration][:new_organization][i + 1][:city] = session[:registration][:new_organization][i][:city]
	# 					end
	# 				end
	# 			else
	# 				if session[:registration][:new_organization][i + 1]
	# 					session[:registration][:new_organization] = session[:registration][:new_organization].first(i + 1)
	# 				end
	# 				if session[:registration][:is_workshop_host]
	# 					next_step = 'new_workshop'
	# 					session[:registration][:workshop] ||= Array.new
	# 					session[:registration][:workshop][0] ||= Hash.new
	# 					session[:registration][:workshop_index] = 0
	# 				else
	# 					complete_registration
	# 					next_step = 'thanks'
	# 				end
	# 			end
	# 		when 'questions'
	# 			if params[:firstname].blank? || params[:lastname].blank?
	# 				error = _'registration.register.no_name_error',"Oh, c'mon, please tell us your name. We promise not to share it with anyone, we just don't want to get you mixed up with someone else."
	# 			end
	# 			session[:registration][:user][:firstname] = params[:firstname]
	# 			session[:registration][:user][:lastname] = params[:lastname]
	# 			session[:registration][:is_volunteer] = false
	# 			session[:registration][:is_participant] = true
	# 			if !session[:registration][:user][:id]
	# 				session[:registration][:user][:username] = !error && params[:username].blank? ? (params[:firstname] + ' ' + params[:lastname]) : params[:username]
	# 			end

	# 			session[:registration][:questions] = params[:questions].deep_symbolize_keys
	# 			session[:registration][:is_workshop_host] = !params[:is_workshop_host].to_i.zero?
	# 			next_step = 'organizations'
	# 			if params[:cancel].blank?#params[:submit] || params[:next]
	# 				if !session[:registration][:organizations]
	# 					user = User.find_by(:email => session[:registration][:email])
	# 					session[:registration][:organizations] = Array.new
	# 					if user
	# 						user.organizations.each { |org| session[:registration][:organizations] << org.id }
	# 					end
	# 				end
	# 				create_registration
	# 			end
	# 		when 'volunteer_questions'
	# 			session[:registration][:volunteer_questions] = params[:volunteer_questions].deep_symbolize_keys
	# 			if session[:registration][:is_participant]
	# 				next_step = 'questions'
	# 			else
	# 				create_registration
	# 				next_step = 'thanks'
	# 			end
	# 		when 'new_workshop'
	# 			i = params[:workshop_index].to_i
	# 			session[:registration][:workshop][i][:title] = params[:workshop_title]
	# 			session[:registration][:workshop][i][:info] = params[:workshop_info]
	# 			session[:registration][:workshop][i][:stream] = params[:workshop_stream]
	# 			session[:registration][:workshop][i][:presentation_style] = params[:workshop_presentation_style]
	# 			session[:registration][:workshop][i][:notes] = params[:workshop_notes]

	# 			if params[:workshop_title].blank?
	# 				error = _'registration.register.no_workshop_title_error','Please give your workshop a title'
	# 			end

	# 			if params[:workshop_info].blank?
	# 				error ||= _'registration.register.no_workshop_info_error','Please describe your workshop as best as you can to give other participants an idea of what to expect'
	# 			end

	# 			update_registration_data

	# 			if params[:previous]
	# 				session[:registration][:workshop_index] = [0, i - 1].max
	# 			elsif params[:add_another_workshop]
	# 				next_step = 'new_workshop'
	# 				if !error
	# 					session[:registration][:workshop] ||= Array.new
	# 					session[:registration][:workshop][i + 1] ||= Hash.new
	# 					session[:registration][:workshop_index] = i + 1
	# 				end
	# 			else
	# 				if session[:registration][:workshop][i + 1]
	# 					session[:registration][:workshop] = session[:registration][:workshop].first(i + 1)
	# 				end
	# 				next_step = 'thanks'
	# 				complete_registration
	# 			end
	# 		when 'thanks'
	# 			@registration = ConferenceRegistration.find(session[:registration][:registration_id])
	# 			if @registration.is_confirmed.blank?
	# 				send_confirmation
	# 			end
	# 			next_step = 'thanks'
	# 		when 'cancel'
	# 			if params[:yes]
	# 				session.delete(:registration)
	# 				next_step = 'cancelled'
	# 			else
	# 				return {error: false, next_step: session[:registration][:path].pop}
	# 			end
	# 		when 'already_registered'
	# 			send_confirmation
	# 			next_step = 'thanks'
	# 		when 'paypal-confirmed'
	# 			@registration = ConferenceRegistration.find(session[:registration][:registration_id])
	# 			next_step = 'confirm_payment'
	# 		when 'confirm_payment'
	# 			@registration = ConferenceRegistration.find(session[:registration][:registration_id])
	# 			if params[:confirm_payment]
	# 				info = YAML.load(@registration.payment_info)
	# 				amount = nil
	# 				status = nil
	# 				if is_test?
	# 					status = info[:status]
	# 					amount = info[:amount]
	# 				else
	# 					paypal = PayPal!.checkout!(info[:token], info[:payer_id], PayPalRequest(info[:amount]))
	# 					status = paypal.payment_info.first.payment_status
	# 					amount = paypal.payment_info.first.amount.total
	# 				end
	# 				if status == 'Completed'
	# 					@registration.registration_fees_paid = amount
	# 					@registration.save!
	# 				end
	# 			end
	# 			next_step = 'thanks'
	# 		when 'pay_now', 'payment-confirmed', 'paypal-cancelled'
	# 			next_step = 'thanks'
	# 	end
	# 	session.delete(:registration_step)
	# 	#if params[:previous]
	# 	#	next_step = session[:registration][:path].pop
	# 	#else
	# 	if !params[:cancel] && error
	# 		return {error: true, message: error, next_step: params['step']}
	# 	end
	# 	if session[:registration] && session[:registration][:path] && params['step']
	# 		session[:registration][:path] << params['step']
	# 	end
	# 	#end
	# 	{error: false, next_step: params[:cancel] ? 'cancel' : next_step}
	# end

	# def broadcast
	# 	set_conference
	# 	set_conference_registration
	# 	raise ActiveRecord::PremissionDenied unless (current_user && @this_conference.host?(current_user))

	# 	@subject = params[:subject]
	# 	@content = params[:content]

	# 	if request.post?
	# 		if params[:button] == 'edit'
	# 			@email_sent = :edit
	# 		elsif params[:button] == 'test'
	# 			@email_sent = :test
	# 			UserMailer.delay.broadcast(
	# 				"#{request.protocol}#{request.host_with_port}",
	# 				@subject,
	# 				@content,
	# 				current_user,
	# 				@this_conference)
	# 		elsif params[:button] == 'preview'
	# 			@email_sent = :preview
	# 		elsif params[:button] == 'send'
	# 			ConferenceRegistration.where(:conference_id => @this_conference.id).each do |r|
	# 				if r.user_id
	# 					UserMailer.broadcast("#{request.protocol}#{request.host_with_port}",
	# 						@subject,
	# 						@content,
	# 						User.find(r.user_id),
	# 						@this_conference).deliver_later
	# 				end
	# 			end
	# 			@email_sent = :yes
	# 		end
	# 	end
	# end

	# def stats
	# 	set_conference
	# 	set_conference_registration
	# 	raise ActiveRecord::PremissionDenied unless (current_user && @this_conference.host?(current_user))

	# 	@registrations = ConferenceRegistration.where(:conference_id => @this_conference.id)

	# 	@total_registrations = 0
	# 	@donation_count = 0
	# 	@total_donations = 0
	# 	@housing = {}
	# 	@bikes = {}
	# 	@bike_count = 0
	# 	@languages = {}
	# 	@food = {}
	# 	@allergies = []
	# 	@other = []

	# 	if request.format.xls?
	# 		logger.info "Generating stats.xls"
	# 		@excel_data = {
	# 			:columns => [:name, :email, :city, :date, :languages, :arrival, :departure, :housing, :companion, :bike, :food, :allergies, :other, :fees_paid],
	# 			:key => 'articles.conference_registration.headings',
	# 			:data => []
	# 		}
	# 	end

	# 	@registrations.each do |r|
	# 		if r && r.is_attending
	# 			begin
	# 				@total_registrations += 1
					
	# 				@donation_count += 1 if r.registration_fees_paid
	# 				@total_donations += r.registration_fees_paid unless r.registration_fees_paid.blank?

	# 				unless r.housing.blank?
	# 					@housing[r.housing.to_sym] ||= 0
	# 					@housing[r.housing.to_sym] += 1
	# 				end

	# 				unless r.bike.blank?
	# 					@bikes[r.bike.to_sym] ||= 0
	# 					@bikes[r.bike.to_sym] += 1
	# 					@bike_count += 1 unless r.bike.to_sym == :none
	# 				end

	# 				unless r.food.blank?
	# 					@food[r.food.to_sym] ||= 0
	# 					@food[r.food.to_sym] += 1
	# 				end

	# 				@allergies << r.allergies unless r.allergies.blank?
	# 				@other << r.other unless r.other.blank?

	# 				JSON.parse(r.languages).each do |l|
	# 					@languages[l.to_sym] ||= 0
	# 					@languages[l.to_sym] += 1
	# 				end unless r.languages.blank?

	# 				if @excel_data
	# 					user = r.user_id ? User.find(r.user_id) : nil
	# 					@excel_data[:data] << {
	# 						:name => (user ? user.firstname : nil) || '',
	# 						:email => (user ? user.email : nil) || '',
	# 						:date => r.created_at ? r.created_at.strftime("%F %T") : '',
	# 						:city => r.city || '',
	# 						:languages => ((JSON.parse(r.languages || '[]').map { |x| I18n.t"languages.#{x}" }).join(', ').to_s),
	# 						:arrival => r.arrival ? r.arrival.strftime("%F %T") : '',
	# 						:departure => r.departure ? r.departure.strftime("%F %T") : '',
	# 						:housing => (I18n.t"articles.conference_registration.questions.housing.#{r.housing || 'none'}"),
	# 						:companion => (r.housing_data[:companions] || []).join(', '),
	# 						:bike => (I18n.t"articles.conference_registration.questions.bike.#{r.bike || 'none'}"),
	# 						:food => (I18n.t"articles.conference_registration.questions.food.#{r.food || 'meat'}"),
	# 						:fees_paid => (r.registration_fees_paid || 0.0),
	# 						:allergies => r.allergies || '',
	# 						:other => r.other || ''
	# 					}
	# 				end
	# 			rescue => error
	# 				logger.info "Error adding row to stats.xls: #{error.message}"
	# 				logger.info error.backtrace.join("\n\t")
	# 			end
	# 		end
	# 	end

	# 	if ENV["RAILS_ENV"] == 'test' && request.format.xls?
	# 		logger.info "Rendering stats.xls as HTML"
	# 		request.format = :html
	# 		respond_to do |format|
	# 			format.html { render :file => 'application/excel.xls.haml', :formats => [:xls] }
	# 		end
	# 		return
	# 	end

	# 	logger.info "Rendering stats.xls" if request.format.xls?

	# 	respond_to do |format|
	# 		format.html
	# 		format.text { render :text => content }
	# 		format.xls { render 'application/excel' }
	# 	end

	# end

	def register
		# is_post = request.post? || session[:registration_step]
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

					# if ENV['RAILS_ENV'] == 'test'
					#	@amount = YAML.load(@registration.payment_info)[:amount]
					# else
					@amount = PayPal!.details(params[:token]).amount.total
					# testing this does't work in test but it works in devo and prod
					@registration.payment_info = {:payer_id => params[:PayerID], :token => params[:token], :amount => @amount}.to_yaml
					# end

					@amount = (@amount * 100).to_i.to_s.gsub(/^(.*)(\d\d)$/, '\1.\2')

					@registration.save!
					@register_template = :paypal_confirm
				end
				@register_template = :paypal_confirm
			elsif form_step == :paypal_confirmed
				#@register_template = :paypal_confirm
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
					@registration.save!
				else
					@errors = :incomplete
					@register_template = :payment
				end
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
						@register_template = steps[steps.find_index(form_step) + 1]

						# have we reached a new level?
						unless @registration.steps_completed.include? form_step.to_s
							@registration.steps_completed ||= []
							@registration.steps_completed << form_step

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
			@registration.housing_data ||= { }
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
			@admin_step = params[:admin_step] || 'edit'
			return do_404 unless view_context.valid_admin_steps.include?(@admin_step.to_sym)
			@page_title = 'articles.conference_registration.headings.Administration'

			case @admin_step.to_sym
			when :organizations
				@organizations = Organization.all

				if request.format.xlsx?
					logger.info "Generating stats.xls"
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
				@registrations = ConferenceRegistration.where(:conference_id => @this_conference.id)

				if request.format.xlsx?
					logger.info "Generating stats.xls"
					@excel_data = {
						columns: [:name, :email, :city, :date, :languages],
						column_types: {date: :date},
						keys: {
								name: 'forms.labels.generic.name',
								email: 'forms.labels.generic.email',
								city: 'forms.labels.generic.location',
								date: 'articles.conference_registration.terms.Date',
								languages: 'articles.conference_registration.terms.Languages'
							},
						data: [],
					}
					@registrations.each do | r |
						user = r.user_id ? User.where(id: r.user_id).first : nil
						if user.present?
							@excel_data[:data] << {
								name: user.firstname || '',
								email: user.email || '',
								date: r.created_at ? r.created_at.strftime("%F %T") : '',
								city: r.city || '',
								languages: ((r.languages || []).map { |x| view_context.language x }).join(', ').to_s
							}
						end
					end
					return respond_to do | format |
						# format.html
						format.xlsx { render xlsx: :stats, filename: "stats-#{DateTime.now.strftime('%Y-%m-%d')}" }
					end
				else
					@registration_count = @registrations.size
					@bikes = @registrations.count { |r| r.bike == 'yes' }
					@donation_count =0
					@donations = 0
					@food = { meat: 0, vegan: 0, vegetarian: 0, all: 0 }
					@registrations.each do | r |
						if r.food.present?
							@food[r.food.to_sym] += 1
							@food[:all] += 1
						end

						if r.registration_fees_paid.present? && r.registration_fees_paid > 0
							@donation_count += 1
							@donations += r.registration_fees_paid
						end
					end
				end
			when :housing
				# do a full analysis
				analyze_housing
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
			else
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
		@guests.each do | guest_id, guest |
			data = guest.housing_data || {}
			@hosts_affected_by_guests[guest_id] ||= []

			if data['host']
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

					# make sure the host isn't overbooked
					space_available = ((host_data['space'] || {})[space.to_s] || 0).to_i
					if @housing_data[host_id][:guests][space].size > space_available
						@housing_data[host_id][:warnings] ||= {}
						@housing_data[host_id][:warnings][:space] ||= {}
						@housing_data[host_id][:warnings][:space][space] ||= []
						@housing_data[host_id][:warnings][:space][space] << :overbooked
					end

					companions = data['companions'] || []
					companions.each do | companion |
						user = User.find_by_email(companion)
						if user.present?
							reg = ConferenceRegistration.find_by(
									:user_id => user.id,
									:conference_id => @this_conference.id
								)
							housing_data = reg.housing_data || {}
							companion_host = housing_data['host'].present? ? housing_data['host'].to_i : nil
							if companion_host.blank?
								@hosts_affected_by_guests[guest_id] << companion_host
								if companion_host != host_id
									# set this as an error if the guest has selected only one other to stay with, but if they have requested to stay with more, make this only a warning
									status = companions.size > 1 ? :warnings : :errors
									@housing_data[host_id][:guests][guest][status] ||= {}
									@housing_data[host_id][:guests][guest][status][:companions] ||= []
									@housing_data[host_id][:guests][guest][status][:companions] << reg.id
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
				@this_conference.paypal_email_address = params[:paypal_email_address]
				@this_conference.paypal_username = params[:paypal_username]
				@this_conference.paypal_password = params[:paypal_password]
				@this_conference.paypal_signature = params[:paypal_signature]
				@this_conference.save
				return redirect_to register_step_path(@this_conference.slug, :administration)
			when 'add_member'
				org = nil
				@this_conference.organizations.each do | organization |
					org = organization if organization.id == params[:org_id].to_i
				end
				org.users << (User.get params[:email])
				org.save
				return redirect_to administration_step_path(@this_conference.slug, :edit)
			end
		when 'housing'
			space = params[:button].split(':')[0]
			host_id = params[:button].split(':')[1].to_i
			guest_id = params[:guest_id].to_i
			
			get_housing_data

			# modify the guest data
			@guests[guest_id].housing_data ||= {}
			@guests[guest_id].housing_data['space'] = space
			@guests[guest_id].housing_data['host'] = host_id
			@guests[guest_id].save!

			if request.xhr?
				analyze_housing

				# get the hosts that need updating
				affected_hosts = {}
				affected_hosts[host_id] = @hosts[host_id]
				if params['affected-hosts'].present?
					params['affected-hosts'].split(',').each do | id |
						affected_hosts[id.to_i] = @hosts[id.to_i]
					end
				end
				@hosts_affected_by_guests[guest_id].each do | id |
					affected_hosts[id] ||= @hosts[id]
				end

				json = { hosts: {}, affected_hosts: @hosts_affected_by_guests }
				puts @hosts_affected_by_guests[guest_id].to_json.to_s
				affected_hosts.each do | id, host |
					json[:hosts][id] = view_context.host_guests_widget(host)
				end
				return render json: json
			end
			return redirect_to administration_step_path(@this_conference.slug, :housing)
		when 'broadcast'
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
				location.title = params[:title]
				location.address = params[:address]
				location.amenities = (params[:needs] || {}).keys.to_json
				location.space = params[:space]
				location.save!
				return redirect_to administration_step_path(@this_conference.slug, :locations)
			when 'cancel'
				return redirect_to administration_step_path(@this_conference.slug, :locations)
			when 'delete'
				location = EventLocation.find_by! id: params[:id].to_i, conference_id: @this_conference.id
				location.destroy
				return redirect_to administration_step_path(@this_conference.slug, :locations)
			when 'create'
				EventLocation.create(
						conference_id: @this_conference.id,
						title: params[:title],
						address: params[:address],
						amenities: (params[:needs] || {}).keys.to_json,
						space: params[:space]
					)
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

	# def registrations
	# 	registrations = ConferenceRegistration.where(:conference_id => @conference.id)
	# 	@registrations = registrations
	# end

	# def register_confirm
	# 	set_conference
	# 	@conference_registration = ConferenceRegistration.find_by(confirmation_token: params[:confirmation_token])
	# 	if !@conference_registration.nil? && @conference_registration.conference_id == @conference.id && !@conference_registration.complete
	# 		@conference_registration.is_confirmed = true
	# 		@conference_registration.save!
	# 		session[:registration] = YAML.load(@conference_registration.data)
	# 		session[:registration][:path] = Array.new
	# 		session[:registration][:registration_id] = @conference_registration.id
	# 		session[:registration_step] = 'confirm'
	# 		redirect_to action: 'register'
	# 	else
	# 		return do_404
	# 	end
	# end

	# def register_pay_registration
	# 	set_conference
	# 	@conference_registration = ConferenceRegistration.find_by(confirmation_token: params[:confirmation_token])
	# 	host = "#{request.protocol}#{request.host_with_port}"
	# 	if !@conference_registration.nil? && @conference_registration.conference_id == @conference.id && @conference_registration.complete
	# 		amount = (params[:auto_payment_amount] || params[:payment_amount]).to_f
	# 		if amount > 0
	# 			response = PayPal!.setup(
	# 				PayPalRequest(amount),
	# 				host + (@conference.url + "/register/paypal-confirm/#{@conference_registration.payment_confirmation_token}/").gsub(/\/\/+/, '/'),
	# 				host + (@conference.url + "/register/paypal-cancel/#{@conference_registration.confirmation_token}/").gsub(/\/\/+/, '/')
	# 			)
	# 			redirect_to response.redirect_uri
	# 		else
	# 			session[:registration] = YAML.load(@conference_registration.data)
	# 			session[:registration][:registration_id] = @conference_registration.id
	# 			session[:registration][:path] = Array.new
	# 			session[:registration_step] = 'pay_now'
	# 			redirect_to action: 'register'
	# 		end
	# 	else
	# 		return do_404
	# 	end
	# end

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
	# 		return do_404
	# 	end
	# end

	# def register_paypal_cancel
	# 	set_conference
	# 	@conference_registration = ConferenceRegistration.find_by(confirmation_token: params[:confirmation_token])
	# 	if !@conference_registration.nil? && @conference_registration.conference_id == @conference.id && @conference_registration.complete && @conference_registration.payment_info.nil?
	# 		session[:registration] = YAML.load(@conference_registration.data)
	# 		redirect_to action: 'register'
	# 	end
	# end

	# def register_step
	# 	set_conference
	# 	data = params
	# 	if params[:conference][:user][:email]
	# 		user = User.find_by(:email => params[:conference][:user][:email])
	# 		data[:conference][:user][:username] = user.username
	# 	end
	# 	render json: data
	# end

	# def add_field
	# 	set_conference
	# 	field = RegistrationFormField.find(params[:field])
	# 	@conference.registration_form_fields << field

	# 	@registration_form_fields = RegistrationFormField.where(["id NOT IN (?)", @conference.registration_form_fields.map(&:id)])

	# 	form = render_to_string :partial => 'registration_form_fields/conference_form'
	# 	list = render_to_string :partial => 'registration_form_fields/list'
	# 	render json: {form: form, list: list}
	# end

	# def remove_field
	# 	set_conference
	# 	field = RegistrationFormField.find(params[:field])
	# 	@conference.registration_form_fields.delete(field)

	# 	@registration_form_fields = RegistrationFormField.where(["id NOT IN (?)", @conference.registration_form_fields.map(&:id)])

	# 	form = render_to_string :partial => 'registration_form_fields/conference_form'
	# 	list = render_to_string :partial => 'registration_form_fields/list'
	# 	render json: {form: form, list: list}
	# end

	# def reorder
	# 	set_conference
	# 	params[:registration_form_field_id].each do |key, value|
	# 		update_field_position(value.to_i, params[:position][key].to_i)
	# 	end
	# 	render json: [].to_json
	# end

	# def form
	# 	set_conference
	# end

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

				return redirect_to workshops_url
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
		user = User.find_by_email(params[:email]) || User.create(email: params[:email])

		set_conference
		set_conference_registration!
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

			UserMailer.send_mail :workshop_comment, comment.user.locale do
				[ workshop, new_comment, comment.user ]
			end
		elsif params[:button] = 'add_comment'
			new_comment = workshop.add_comment(current_user, params[:comment])

			workshop.active_facilitators.each do | u |
				UserMailer.send_mail :workshop_comment, u.locale do
					[ workshop, new_comment, u ]
				end
			end
		else
			return do_404
		end

		return redirect_to view_workshop_url(@this_conference.slug, workshop.id, anchor: "comment-#{new_comment.id}")
	end

	# def schedule
	# 	set_conference
	# 	return do_404 unless @this_conference.workshop_schedule_published || @this_conference.host?(current_user)
		
	# 	@events = Event.where(:conference_id => @this_conference.id).order(start_time: :asc)
	# 	@locations = EventLocation.where(:conference_id => @this_conference.id)

	# 	render 'schedule/show'
	# end

	# def edit_schedule
	# 	set_conference
	# 	return do_404 unless @this_conference.host?(current_user)
		
	# 	@workshops = Workshop.where(:conference_id => @this_conference.id)
	# 	@events = Event.where(:conference_id => @this_conference.id)
	# 	if session[:workshops]
	# 		(0...@workshops.count).each do |i|
	# 			id = @workshops[i].id
	# 			w = session[:workshops][id.to_s]
	# 			if w
	# 				@workshops[i].start_time = w[:start_time]
	# 				@workshops[i].end_time = w[:end_time]
	# 				@workshops[i].event_location_id = w[:event_location_id]
	# 			end
	# 		end
	# 	end
	# 	if session[:events]
	# 		(0...@events.count).each do |i|
	# 			id = @events[i].id
	# 			w = session[:events][id.to_s]
	# 			if w
	# 				@events[i].start_time = w[:start_time]
	# 				@events[i].end_time = w[:end_time]
	# 				@events[i].event_location_id = w[:event_location_id]
	# 			end
	# 		end
	# 	end
	# 	@locations = EventLocation.where(:conference_id => @this_conference.id)
	# 	@location_hash = Hash.new
	# 	@locations.each do |l|
	# 		@location_hash[l.id.to_s] = l
	# 	end

	# 	@days = Array.new
	# 	start_day = @this_conference.start_date.strftime('%u').to_i
	# 	end_day = start_day + ((@this_conference.end_date - @this_conference.start_date) / 86400)

	# 	(start_day..end_day).each do |i|
	# 		@days << [(@this_conference.start_date + (i - start_day).days).strftime('%a'), ((i + 1) - start_day)]
	# 	end

	# 	@hours = Array.new
	# 	(0..48).each do |i|
	# 		hour = (Date.today + (i / 2.0).hours).strftime('%R')
	# 		@hours << hour
	# 	end

	# 	@event_durations = [['30 mins', 30], ['1 hour', 60], ['1.5 hours', 90], ['2 hours', 120], ['2.5 hours', 150]]
	# 	@workshop_durations = [['1 hour', 60], ['1.5 hours', 90], ['2 hours', 120]]

	# 	schedule_data = get_schedule_data
	# 	@schedule = schedule_data[:schedule]
	# 	@errors = schedule_data[:errors]
	# 	@warnings = schedule_data[:warnings]
	# 	@conflict_score = schedule_data[:conflict_score]
	# 	@error_count = schedule_data[:error_count]
	# 	if session[:day_parts]
	# 		@day_parts = JSON.parse(session[:day_parts])
	# 	elsif @this_conference.day_parts
	# 		@day_parts = JSON.parse(@this_conference.day_parts)
	# 	else
	# 		@day_parts = {:morning => 0, :afternoon => 13, :evening => 18}
	# 	end
	# 	@saved = session[:workshops].nil?

	# 	render 'schedule/edit'
	# end

	# def save_schedule
	# 	set_conference
	# 	return do_404 unless @this_conference.host?(current_user)

	# 	@days = Array.new
	# 	start_day = @this_conference.start_date.strftime('%u').to_i
	# 	end_day = start_day + ((@this_conference.end_date - @this_conference.start_date) / 86400)

	# 	(start_day..end_day).each do |i|
	# 		@days << [(@this_conference.start_date + (i - start_day).days).strftime('%a'), i]
	# 	end

	# 	@workshops = Workshop.where(:conference_id => @this_conference.id)
	# 	@events = Event.where(:conference_id => @this_conference.id)
	# 	@locations = EventLocation.where(:conference_id => @this_conference.id)

	# 	do_save = (params[:button] == 'save' || params[:button] == 'publish')
	# 	session[:workshops] = do_save ? nil : Hash.new
	# 	session[:events] = do_save ? nil : Hash.new
	# 	session[:day_parts] = do_save ? nil : Hash.new

	# 	(0...@workshops.count).each do |i|
	# 		id = @workshops[i].id.to_s
	# 		if params[:workshop_day][id].present? && params[:workshop_hour][id].present? && params[:workshop_duration][id].present?
	# 			date = @this_conference.start_date + (params[:workshop_day][id].to_i - 1).days
	# 			h = params[:workshop_hour][id].split(':')
	# 			date = date.change({hour: h.first, minute: h.last})
	# 			@workshops[i].start_time = date
	# 			@workshops[i].end_time = date + (params[:workshop_duration][id].to_i).minutes
	# 		else
	# 			@workshops[i].start_time = nil
	# 			@workshops[i].end_time = nil
	# 		end
	# 		@workshops[i].event_location_id = params[:workshop_location][id]
	# 		if do_save
	# 			@workshops[i].save
	# 		else
	# 			session[:workshops][id] = {
	# 				:start_time => @workshops[i].start_time,
	# 				:end_time => @workshops[i].end_time,
	# 				:event_location_id => @workshops[i].event_location_id
	# 			}
	# 		end
	# 	end

	# 	(0...@events.count).each do |i|
	# 		id = @events[i].id.to_s
	# 		if params[:event_day][id].present? && params[:event_hour][id].present? && params[:event_duration][id].present?
	# 			date = @this_conference.start_date + (params[:event_day][id].to_i - 1).days
	# 			h = params[:event_hour][id].split(':')
	# 			date = date.change({hour: h.first, minute: h.last})
	# 			@events[i].start_time = date
	# 			@events[i].end_time = date + (params[:event_duration][id].to_i).minutes
	# 		else
	# 			@events[i].start_time = nil
	# 			@events[i].end_time = nil
	# 		end
	# 		@events[i].event_location_id = params[:event_location][id]
	# 		if do_save
	# 			@events[i].save
	# 		else
	# 			session[:events][id] = {
	# 				:start_time => @events[i].start_time,
	# 				:end_time => @events[i].end_time,
	# 				:event_location_id => @events[i].event_location_id
	# 			}
	# 		end
	# 	end

	# 	if params[:day_parts]
	# 		day_parts = {:morning => 0}
	# 		params[:day_parts].each do |part, h|
	# 			h = h.split(':')
	# 			day_parts[part.to_sym] = h[0].to_f + (h[1].to_i > 0 ? 0.5 : 0)
	# 		end
	# 		if do_save
	# 			@this_conference.day_parts = day_parts.to_json
	# 		else
	# 			session[:day_parts] = day_parts.to_json
	# 		end
	# 	end

	# 	save_conference = do_save

	# 	if params[:button] == 'publish'
	# 		@this_conference.workshop_schedule_published = true
	# 		save_conference = true
	# 	elsif params[:button] == 'unpublish'
	# 		@this_conference.workshop_schedule_published = false
	# 		save_conference = true
	# 	end

	# 	if save_conference
	# 		@this_conference.save
	# 	end

	# 	redirect_to edit_schedule_url(@this_conference.slug)
	# end

	# def add_event
	# 	set_conference
	# 	return do_404 unless @this_conference.host?(current_user)
		
	# 	render 'events/edit'
	# end

	# def edit_event
	# 	set_conference
	# 	return do_404 unless @this_conference.host?(current_user)

	# 	@event = Event.find(params[:id])
	# 	return do_403 unless @event.conference_id == @this_conference.id

	# 	render 'events/edit'
	# end

	# def save_event
	# 	set_conference
	# 	return do_404 unless @this_conference.host?(current_user)


	# 	if params[:event_id]
	# 		event = Event.find(params[:event_id])
	# 		return do_403 unless event.conference_id == @this_conference.id
	# 	else
	# 		event = Event.new(:conference_id => @this_conference.id)
	# 	end

	# 	event.title = params[:title]
	# 	event.info = params[:info]
	# 	event.event_type = params[:event_type]

	# 	event.save

	# 	return redirect_to schedule_url(@this_conference.slug)
	# end

	# def add_location
	# 	set_conference
	# 	return do_404 unless @this_conference.host?(current_user)
		
	# 	render 'event_locations/edit'
	# end

	# def edit_location
	# 	set_conference
	# 	return do_404 unless @this_conference.host?(current_user)

	# 	@location = EventLocation.find(params[:id])
	# 	return do_403 unless @location.conference_id == @this_conference.id

	# 	@amenities = JSON.parse(@location.amenities || '[]').map &:to_sym

	# 	render 'event_locations/edit'
	# end

	# def save_location
	# 	set_conference
	# 	return do_404 unless @this_conference.host?(current_user)


	# 	if params[:location_id]
	# 		location = EventLocation.find(params[:location_id])
	# 		return do_403 unless location.conference_id == @this_conference.id
	# 	else
	# 		location = EventLocation.new(:conference_id => @this_conference.id)
	# 	end

	# 	location.title = params[:title]
	# 	location.address = params[:address]
	# 	location.amenities = (params[:needs] || {}).keys.to_json

	# 	location.save

	# 	return redirect_to schedule_url(@this_conference.slug)
	# end

	# DELETE /conferences/1
	#def destroy
	#	@conference.destroy
	#	redirect_to conferences_url, notice: 'Conference was successfully destroyed.'
	#end

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

	rescue_from ActiveRecord::PremissionDenied do |exception|
		if logged_in?
			redirect_to :register
		else
			@register_template = :confirm_email
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
