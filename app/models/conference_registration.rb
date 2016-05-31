class ConferenceRegistration < ActiveRecord::Base
	belongs_to :conference
	belongs_to :user
    has_many :conference_registration_responses

    AttendingOptions = [:yes, :no]

    def languages
    	user.languages
    end
end
