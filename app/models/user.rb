class User < ActiveRecord::Base
	authenticates_with_sorcery! do |config|
        config.authentications_class = Authentication
    end

	validates :password, presence: true, confirmation: true, length: { minimum: 3 }, unless: ("id?" || "password_confirmation?")
	validates :password_confirmation, presence: true, unless: ("id?" || "password?")

	validates :email, uniqueness: true

	#validates_presence_of :avatar
	#validates_integrity_of  :avatar
	#validates_processing_of :avatar

	#has_secure_password validations: false

	mount_uploader :avatar, AvatarUploader

	has_many :user_organization_relationships
	has_many :organizations, through: :user_organization_relationships
    has_many :authentications, :dependent => :destroy
    accepts_nested_attributes_for :authentications

end
