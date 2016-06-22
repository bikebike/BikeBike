require 'geocoder'
require 'geocoder/railtie'

Geocoder::Railtie.insert

class EventLocation < ActiveRecord::Base
	belongs_to :conference
	geocoded_by :full_address

	reverse_geocoded_by :latitude, :longitude, :address => :full_address
	after_validation :geocode, if: ->(obj){ obj.address_changed? }

	def full_address
		l = conference.location
		[address, l.city, l.territory, l.country].join(', ')
	end

    def self.all_spaces
        Workshop.all_spaces + [:event_space]
    end

    def self.all_amenities
        Workshop.all_needs
    end
end
