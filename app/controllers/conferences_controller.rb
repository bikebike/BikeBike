require 'geocoder/calculations'
require 'rest_client'

class ConferencesController < ApplicationController
	before_action :set_conference, only: [:show, :edit, :update, :destroy]

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
		if !current_user
			raise ActiveRecord::PremissionDenied
		end
		@host = @conference.organizations[0].locations[0]
		#points = Geocoder::Calculations.bounding_box([@host.latitude, @host.longitude], 50, { :unit => :km })
		result = Geocoder.search(@host.city + ', ' + @host.territory + ' ' + @host.country).first
		points = Geocoder::Calculations.bounding_box([result.latitude, result.longitude], 5, { :unit => :km })
		response = RestClient.get 'http://www.panoramio.com/map/get_panoramas.php', :params => {:set => :public, :size => :original, :from => 0, :to => 20, :mapfilter => false, :miny => points[0], :minx => points[1], :maxy => points[2], :maxx => points[3]}
		if response.code == 200
			@parse_data = JSON.parse(response.to_str)
		end
	end

	# POST /conferences
	def create
		@conference = Conference.new(conference_params)

		if @conference.save
			redirect_to @conference, notice: 'Conference was successfully created.'
		else
			render action: 'new'
		end
	end

	# PATCH/PUT /conferences/1
	def update
		if params[:register]
			registration = ConferenceRegistration.find_by(:user_id => current_user.id, :conference_id => @conference.id)
			if registration
				registration.conference_registration_responses.destroy_all
				registration.is_attending = params[:is_attending]
			else
				registration = ConferenceRegistration.new(user_id: current_user.id, conference_id: @conference.id, is_attending: params[:is_attending])
			end
			data = Hash.new
			params.each do |key, value|
				matches = /^field_(\d+)(_(\d+|other))?/.match(key)
				if matches
					if matches[3] == nil
						data[matches[1]] = value
					else
						data[matches[1]] ||= Hash.new
						data[matches[1]][matches[3]] = value
					end
				end
			end
			data.each do |key, value|
				registration.conference_registration_responses << ConferenceRegistrationResponse.new(registration_form_field_id: key.to_i, data: value.to_json)
			end
			registration.save!
			render action: 'show'
		elsif @conference.update(conference_params)
			redirect_to @conference, notice: 'Conference was successfully updated.'
		else
			render action: 'edit'
		end
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
					registration = ConferenceRegistration.find(session[:registration][:registration_id])
					if registration.completed
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
					next_step = 'primary'
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
				if params[:name].blank?
					error = _'register.new_organization.no_name_error',"Please tell us your organization's name"
				end
				if params[:organization_email].blank?
					error ||= _'register.new_organization.no_email_error',"Please tell us your organization's email address. We need it so that we can send out invitations for upcoming conferences. No spam, we promise, and you'll be able to edit your preferences before we start ending out email."
				elsif params[:organization_email].strip.casecmp(session[:registration][:email].strip)
					error ||= _'register.new_organization.same_email_as_attendee_error',"This email needs to be different than your own personal email, we need to keep in touch with your organization even if you're gone in years to come."
				end
				if params[:street].blank?
					error ||= _'register.new_organization.no_street_error','Please enter your organization\'s street address'
				end
				if params[:city].blank?
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
				session[:registration][:questions] = params[:questions].deep_symbolize_keys
				session[:registration][:is_workshop_host] = !params[:is_workshop_host].to_i.zero?
				next_step = 'organizations'
				if params[:submit] || params[:next]
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
					paypal = PayPal!.checkout!(info[:token], info[:payer_id], PayPalRequest(info[:amount]))
					if paypal.payment_info.first.payment_status == 'Completed'
						@registration.registration_fees_paid = paypal.payment_info.first.amount.total
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
	
	def register
		is_post = request.post? || session[:registration_step]
		set_conference

		if !@conference.registration_open
			do_404
			return
		end

		data = register_submit
		@register_step = is_post ? data[:next_step] : 'register'
		@error_message = data[:error] ? data[:message] : nil
		template = (@register_step == 'register' ? '' : 'register_') + @register_step

		if !File.exists?(Rails.root.join("app", "views", params[:controller], "_#{template}.html.haml"))
			do_404
			return
		end
		
		if session[:registration]
			session[:registration][@register_step.to_sym] ||= Hash.new
		end
		@actions = nil
		@multipart = false
		case @register_step
			when  'register', 'organizations', 'new_organization', 'new_workshop', 'volunteer_questions'
				@actions = :next
				if @register_step == 'new_organization'
					@multipart = true
				end
			when 'thanks'
				@registration = ConferenceRegistration.find(session[:registration][:registration_id])
				if @registration.is_confirmed.blank?
					@actions = :resend_confirmation_email
				end
				next_step = 'thanks'
				#if @registration.complete && @registration.is_participant && @registration.payment_info.nil?
				#`	@actions = [:submit_payment]
			when 'primary'
				@actions = [:cancel, :next]
			when 'submit'
				@actions = [:cancel, :submit]
			when 'cancel'
				@actions = [:no, :yes]
			when 'confirm_payment'
				@actions = [:cancel_payment, :confirm_payment]
			when 'already_registered'
				@registration = ConferenceRegistration.find_by(:email => session[:registration][:email])
				if !@registration.complete
					@actions = :resend_confirmation_email
				end
			when 'questions'
				@actions = [:cancel, :submit]
				@housing_options = {
					'I will fend for myself thanks' => 'none',
					'I will need a real bed' => 'bed',
					'A couch or floor space will be fine' => 'couch',
					'All I need is a backyard' => 'camp'
				}
				session[:registration][:questions][:housing] ||= 'couch'
				@loaner_bike_options = {
					'No' => 'no',
					'Yes, an average size should do' => 'medium',
					'Yes but a small one please' => 'small',
					'Yes but a large one please' => 'large'
				}
				session[:registration][:questions][:loaner_bike] ||= 'medium'
				#session[:registration][:questions][:diet] ||= Hash.new
		end

		#puts ' ------yyyy----------------- '
		#puts @register_step

		if request.xhr?
			@register_content = render_to_string :partial => template
			render :json => {status: 200, html: @register_content}
		else
			@register_template = template
			render 'show'
		end
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

	def register_paypal_confirm
		set_conference
		@conference_registration = ConferenceRegistration.find_by(payment_confirmation_token: params[:confirmation_token])
		if !@conference_registration.nil? && @conference_registration.conference_id == @conference.id && @conference_registration.complete && @conference_registration.registration_fees_paid.nil?
			@conference_registration.payment_info = {:payer_id => params[:PayerID], :token => params[:token], :amount => PayPal!.details(params[:token]).amount.total}.to_yaml
			@conference_registration.save!
			session[:registration] = YAML.load(@conference_registration.data)
			session[:registration][:registration_id] = @conference_registration.id
			session[:registration][:path] = Array.new
			session[:registration_step] = 'paypal-confirmed'
			redirect_to action: 'register'
		else
			do_404
		end
	end

	def register_paypal_cancel
		set_conference
		@conference_registration = ConferenceRegistration.find_by(confirmation_token: params[:confirmation_token])
		if !@conference_registration.nil? && @conference_registration.conference_id == @conference.id && @conference_registration.complete && @conference_registration.payment_info.nil?
			session[:registration] = YAML.load(@conference_registration.data)
			session[:registration][:registration_id] = @conference_registration.id
			session[:registration][:path] = Array.new
			session[:registration_step] = 'paypal-cancelled'
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
		@workshops = Workshop.where(:conference_id => @conference.id)
		render 'workshops/index'
	end

	# DELETE /conferences/1
	def destroy
		@conference.destroy
		redirect_to conferences_url, notice: 'Conference was successfully destroyed.'
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_conference
			@conference = nil
			if type = ConferenceType.find_by!(slug: params[:conference_type] || params[:conference_type_slug] || 'bikebike')
				if @conference = Conference.find_by!(slug: params[:conference_slug] || params[:slug], conference_type_id: type.id)
					set_conference_registration
				end
			end
			if current_user
				@host_privledge = :admin
			end
		end

		def set_conference_registration
			if !@conference || !current_user
				@conference_registration = nil
				return
			end

			@conference_registration = ConferenceRegistration.find_by(conference_id: @conference.id, user_id: current_user.id)
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
			if !session[:registration][:registration_id]
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
		paypal_info = get_secure_info(:paypal)
		Paypal::Express::Request.new(
			:username   => paypal_info[:username],
			:password   => paypal_info[:password],
			:signature  => paypal_info[:signature]
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
