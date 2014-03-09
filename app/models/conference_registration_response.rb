class ConferenceRegistrationResponse < ActiveRecord::Base
    belongs_to :conference_registration
    belongs_to :user
    #belongs_to :conference, :through => :conference_registration
end
