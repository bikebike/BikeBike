class ConferenceRegistration < ActiveRecord::Base
	belongs_to :conference
	belongs_to :user
	has_many :conference_registration_responses

	AttendingOptions = [:yes, :no]

	def languages
		user.languages
	end

	def self.all_housing_options
		[:none, :tent, :house]
	end

	def self.all_spaces
		[:bed_space, :floor_space, :tent_space]
	end

	def self.all_bike_options
		[:yes, :no]
	end

	def self.all_food_options
		[:meat, :vegetarian, :vegan]
	end

	def self.all_considerations
		[:vegan, :smoking, :pets, :quiet]
	end

	def status(was = false)
		return :unregistered if user.firstname.blank? || self.send(was ? :city_was : :city).blank?
		return :registered if self.send(was ? :housing_was : :housing).present? || (self.send(was ? :can_provide_housing_was : :can_provide_housing) && (self.send(was ? :housing_data_was : :housing_data) || {})['availability'].present?)
		return :preregistered
	end

	around_update :check_status

	def check_status
		yield #saves
		old_status = status(true)
		new_status = status

		puts " ===== #{old_status.to_s} : #{new_status.to_s} ==> #{conference.registration_status} ===== "
		if old_status.present? && old_status != new_status
			if (conference.registration_status == :pre && new_status == :preregistered) ||
				(conference.registration_status == :open && new_status == :registered)

				UserMailer.send_mail :registration_confirmation do
					{
						:args => self
					}
				end
			end
		end
	end

	# before_update do | registration |
	# 	old_status = status
	# 	new_status = registration.status
	# 	puts " ===== #{old_status.to_s} : #{new_status.to_s} ===== "
	# 	if old_status.present? && old_status != new_status
	# 		if (conference.registration_status == :pre && new_status == :preregistered) ||
	# 			(conference.registration_status == :open && new_status == :registered)
	# 		end

	# 		UserMailer.send_mail :registration_confirmation do
	# 			{
	# 				:args => registration
	# 			}
	# 		end
	# 	end
	# end
end
