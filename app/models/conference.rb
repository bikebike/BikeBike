class Conference < ActiveRecord::Base
	translates :info, :title

	mount_uploader :cover, CoverUploader
	mount_uploader :poster, PosterUploader

	belongs_to :conference_type

	has_many :conference_host_organizations, :dependent => :destroy
	has_many :organizations, :through => :conference_host_organizations
	has_many :event_locations
	
	#has_many :conference_registration_form_fields, :order => 'position ASC', :dependent => :destroy#, :class_name => '::ConferenceRegistrationFormField'
	#has_many :registration_form_fields, :through => :conference_registration_form_fields

	has_many :workshops

	accepts_nested_attributes_for :conference_host_organizations, :reject_if => proc {|u| u[:organization_id].blank?}, :allow_destroy => true

	def to_param
		slug
	end

	def host?(user)
		return false unless user.present?
		organizations.each do |o|
			return true if o.host?(user)
		end
		return false
	end

	def url(action = :show)
		path(action)
	end

	def path(action = :show)
		action = action.to_sym
		'/conferences/' + conference_type.slug + '/' + slug + (action == :show ? '' : '/' + action.to_s)
	end

	def location
		organizations.first.location
	end

	def registered?(user)
		registration = ConferenceRegistration.find_by(:user_id => user.id, :conference_id => id)
		return registration ? registration.is_attending : false
	end

	def registration_exists?(user)
		ConferenceRegistration.find_by(:user_id => user.id, :conference_id => id).present?
	end

	def registration_open
		registration_status == :open
	end

	def registration_status
		s = read_attribute(:registration_status)
		s.present? ? s.to_sym : nil
	end

	def registration_status=(new_registration_status)
		write_attribute :registration_status, new_registration_status.to_s
	end

end
