class EmailConfirmation < ActiveRecord::Base
	belongs_to :user
	before_create :prepare

	def prepare
		# clean up any expired records
		EmailConfirmation.delete_all(['expiry < ?', Time.now])

		# fill in defaults
		self.expiry ||= Time.now + 1.day

		while self.token.nil? do
			# create a token based on the user id and current time
			self.token = generate_token

			# conflicts should be extremely rare, but let's just be sure
			if EmailConfirmation.exists?(:token => self.token)
				self.token = nil # keep the loop going
				# because we generate the token based on the time, just make sure
				#  some time has passed
				sleep 0.1
			end
		end
	end

	def valid_for_user?(user)
		user.id == user_id && !expired?
	end

	def expired?
		expiry >= Time.now
	end

	protected

		def generate_token
			Digest::SHA256.hexdigest(user_id.to_s + (Time.now.to_f * 1000000).to_i.to_s)
		end

end
