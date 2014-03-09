class Location < ActiveRecord::Base
	#attr_accessible :title, :country, :territory, :city, :street, :postal_code, :latitude, :longitude
    has_many :locations_organization
    has_many :organizations, :through => :locations_organization

	geocoded_by :full_address
	reverse_geocoded_by :latitude, :longitude, :address => :full_address
	after_validation :geocode, if: ->(obj){ obj.country_changed? or obj.territory_changed? or obj.city_changed? or obj.street_changed? or obj.postal_code_changed? }

	def full_address
		addr = title
		addr = (addr ? ', ' : '') + (street || '')
		addr = (addr ? ', ' : '') + (city || '')
		addr = (addr ? ', ' : '') + (territory || '')
		addr = (addr ? ' ' : '')  + (country || '')
		addr = (addr ? ' ' : '')  + (postal_code || '')
		addr
	end

end
