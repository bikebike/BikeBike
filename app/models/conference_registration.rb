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
end
