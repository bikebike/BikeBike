class User < ActiveRecord::Base
	authenticates_with_sorcery! do |config|
        config.authentications_class = Authentication
    end

	validates :email, uniqueness: true

	mount_uploader :avatar, AvatarUploader

	has_many :user_organization_relationships
	has_many :organizations, through: :user_organization_relationships
    has_many :authentications, :dependent => :destroy
    accepts_nested_attributes_for :authentications

	before_save do |user|
		user.locale = I18n.locale
	end

	def can_translate?(to_locale = nil, from_locale = nil)
		is_translator unless to_locale.present?

		from_locale = I18n.locale unless from_locale.present?
		return languages.present? &&
			to_locale.to_s != from_locale.to_s &&
			languages.include?(to_locale.to_s) &&
			languages.include?(from_locale.to_s)
	end

	def name
		firstname || username || email
	end

	def named_email
		name = firstname || username
		return email unless name
		return "#{name} <#{email}>"
	end

	def self.get(email)
		user = where(email: email).first

		unless user
			# not really a good UX so we should fix this later
			#do_404
			#return
			user = new(email: email)
			user.save!
		end

		return user
	end

end
