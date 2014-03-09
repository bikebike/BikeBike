class ConferenceRegistration < ActiveRecord::Base
    has_many :conference_registration_responses

    AttendingOptions = [:yes, :no]
end
