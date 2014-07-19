class UserMailer < ActionMailer::Base
	default from: "noreply@bikebike.org"

	# Subject can be set in your I18n file at config/locales/en.yml
	# with the following lookup:
	#
	#   en.user_mailer.activation_needed_email.subject
	#
	def activation_needed_email(email_address)
		@greeting = "Hi"

		mail to: 'goodgodwin@hotmail.com'
	end

	# Subject can be set in your I18n file at config/locales/en.yml
	# with the following lookup:
	#
	#   en.user_mailer.activation_success_email.subject
	#
	def activation_success_email
		@greeting = "Hi"

		mail to: "to@example.org"
	end

	def conference_registration_email(conference, data)
		@data = data
		@conference = conference
		mail to: data[:email], subject: 'Please confirm your registration for ' + conference.title
	end
end
