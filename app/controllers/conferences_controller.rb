require 'geocoder/calculations'
require 'rest_client'

class ConferencesController < ApplicationController
	before_action :set_conference, only: [:show, :edit, :update, :destroy]

	# GET /conferences
	def index
		@conferences = Conference.all
	end

	# GET /conferences/1
	def show
		#puts params[:slug]
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

	def register
		set_conference
		@user = User.new
		@sub_action = 'registration_register'
		render :registration
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
			if type = ConferenceType.find_by!(slug: params[:conference_type_slug] || 'bikebike')
				if @conference = Conference.find_by!(slug: params[:conference_slug] || params[:slug], conference_type_id: type.id)
					set_conference_registration
				end
			end
			if current_user
				@host_privledge = :admin
			end
			#if !@conference
			#	raise ActionController::RoutingError.new('Not Found')
			#end
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
end
