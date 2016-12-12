class LocationsOrganization < ActiveRecord::Base
  belongs_to :location
  belongs_to :organization

  self.primary_key = :location_id
end
