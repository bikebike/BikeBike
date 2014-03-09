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

	def to_param
		slug
	end

end
