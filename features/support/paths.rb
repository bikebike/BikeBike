module NavigationHelpers
	def path_to(page_name)
		append_root = false
		case page_name
			when /^landing$/i
				path = :home
			when /^confirmation$/i
				path = "/conferences/bikebike/#{@last_conference.slug}/register/confirm/#{@last_registration.confirmation_token}"
			when /^registration$/i
				path = "/conferences/bikebike/#{@last_conference.slug}/register/"
			when /^pay registration$/i
				path = "/conferences/bikebike/#{@last_conference.slug}/register/pay-registration/#{@last_registration.confirmation_token}"
			when /^confirm paypal$/i
				path = "/conferences/bikebike/#{@last_conference.slug}/register/paypal-confirm/#{@last_registration.payment_confirmation_token}"
			when /^cancel paypal$/i
				path = "/conferences/bikebike/#{@last_conference.slug}/register/paypal-cancel/#{@last_registration.confirmation_token}"
			when /^translation list$/i
				path = '/translations/'
			when /^(.+) translations?$/i
				path = '/translations/' + get_language_code(Regexp.last_match(1))
			when /^organization list$/i
				path = '/organizations/'
		end

		if path.is_a?(Symbol)
			begin
				path = self.send((path.to_s + '_url').to_sym).gsub(/^http:\/\/.+?(\/.*)$/, '\1')
			rescue Object => e
				raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
					"#{path}_url\n" +
					"Now, go and add a mapping in #{__FILE__}"
			end
		end
		path
	end
end

World(NavigationHelpers)
