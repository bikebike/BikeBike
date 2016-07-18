class Organization < ActiveRecord::Base
	mount_uploader :logo, LogoUploader
	mount_uploader :avatar, AvatarUploader
	mount_uploader :cover, CoverUploader

	has_many :locations_organization
	has_many :locations, :through => :locations_organization

	has_many :user_organization_relationships, :dependent => :destroy
	has_many :users, :through => :user_organization_relationships

	accepts_nested_attributes_for :locations, :reject_if => proc {|l| l[id].blank?}
	accepts_nested_attributes_for :user_organization_relationships, :reject_if => proc {|u| u[:user_id].blank?}, :allow_destroy => true
	before_create :make_slug

	def location
		locations.first
	end

	def longitude
		location.longitude
	end

	def latitude
		location.latitude
	end

	def to_param
		slug
	end

	def host?(user)
		return false unless user.present?
		return true if user.administrator?
		
		users.each do |u|
			return true if u.id == user.id
		end
		return false
	end

	def generate_slug(name, location = nil)
		s = name.gsub(/[^a-z1-9]+/i, '-').chomp('-').gsub(/\-([A-Z])/, '\1')
		if Organization.find_by(:slug => s).present? && !location.nil?
			if location.city.present?
				s += '-' + location.city
			end
			if Organization.find_by(:slug => s).present? && location.territory.present?
				s += '-' + location.territory
			end
			if Organization.find_by(:slug => s).present?
				s += '-' + location.country
			end
		end
		attempt = 1
		ss = s

		while Organization.find_by(:slug => s)
			attempt += 1
			s = ss + '-' + attempt.to_s
		end
		s
	end

	private
		def make_slug
			if !self.slug
				self.slug = generate_slug(self.name, self.locations && self.locations[0])
			end
		end
end
