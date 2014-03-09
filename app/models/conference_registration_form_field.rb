class ConferenceRegistrationFormField < ActiveRecord::Base
    belongs_to :conference
    belongs_to :registration_form_field

    acts_as_list
end
