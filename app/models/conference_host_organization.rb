class ConferenceHostOrganization < ActiveRecord::Base
	belongs_to :conference
	belongs_to :organization
end
