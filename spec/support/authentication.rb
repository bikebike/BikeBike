module AuthenticationForFeatureRequest
	def login user, password = 'login'
		user.update_attribute :password, password

		page.driver.post sessions_url, {email: user.email, password: password}
		visit root_url
	end
end
