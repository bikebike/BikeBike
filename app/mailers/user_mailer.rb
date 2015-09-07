class UserMailer < ActionMailer::Base
	add_template_helper(ApplicationHelper)
	#add_template_helper(LinguaFrancaHelper)
	include LinguaFrancaHelper

	#def self.before(*names)
	#	names.each do |name|
	#		m = instance_method(name)
	#		define_method(name) do |*args, &block|  
	#			#yield
	#			if ![:send_action].include?(name.to_sym)
	#				puts " ====== #{name} ====== "
	#				I18n.backend.set_page_name(name)
	#				m.bind(self).(*args, &block)
	#			else
	#				puts " ------ #{name} ------ "
	#			end
	#		end
	#	end
	#end

	default from: "Bike!Bike! <noreply@bikebike.org>"

	# Subject can be set in your I18n file at config/locales/en.yml
	# with the following lookup:
	#
	#   en.user_mailer.activation_needed_email.subject
	#
	def activation_needed_email(email_address)
		@greeting = "Hi"

		mail to: email_address
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

	def test_email
		mail to: 'goodgodwin@hotmail.com', subject: 'This is a test', from: 'info@preview.bikebike.org'
	end

    def conference_registration_email(conference, data, conference_registration)
        @data = data
        @conference = conference
        @url = "https://bikebike.org"#UserMailer.default_url_options[:host]
        @confirmation_url = UserMailer.default_url_options[:host] + "/#{@conference.url}/register/confirm/#{conference_registration.confirmation_token}/".gsub(/\/\/+/, '/')
        mail to: data[:email], subject: (I18n.t 'register.email.registration.subject',"Please confirm your registration for #{conference.title}", vars: {:conference_title => conference.title})
    end

	def conference_registration_confirmed_email(conference, data, conference_registration)
		@data = data
		@conference = conference
		@url = "https://bikebike.org"#UserMailer.default_url_options[:host]
		@confirmation_url = UserMailer.default_url_options[:host] + "/#{@conference.url}/register/pay-registration/#{conference_registration.confirmation_token}/".gsub(/\/\/+/, '/')
		mail to: data[:email], subject: (I18n.t 'register.email.registration_confirmed.subject',"Thanks for confirming your registration for #{conference.title}", vars: {:conference_title => conference.title})
	end

	def email_confirmation(confirmation)
		#puts " == #{instance_methods.to_json.to_s} == "
		@confirmation = confirmation
		@host = UserMailer.default_url_options[:host]
		mail to: confirmation.user.email,
			 subject: (_'email.subject.confirm_email','Please confirm your email address')
	end

	def broadcast(host, subject, content, user, conference)
		#puts " == #{instance_methods.to_json.to_s} == "
		@host = host
		@content = content
		@banner = (@host || 'http://localhost/') + (conference ? (conference.poster.preview.url || '') : image_url('logo.png'))
		if user && user.email
			mail to: user.email, subject: "[#{conference ? conference.title : 'Bike!Bike!'}] #{subject}"
		end
	end

	#before(*instance_methods) { }
end
