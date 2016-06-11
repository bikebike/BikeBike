require 'diffy'

class UserMailer < ActionMailer::Base
	add_template_helper(ApplicationHelper)
	include LinguaFrancaHelper

	before_filter :set_host

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
		@confirmation = confirmation
		@subject = _'email.subject.confirm_email','Please confirm your email address'
		mail to: confirmation.user.named_email, subject: @subject
	end

	def registration_confirmation(registration)
		@registration = registration
		@conference = Conference.find(@registration.conference_id)
		@user = User.find(@registration.user_id)
		@subject = @conference.registration_status.to_sym == :pre ?
			_(
				'email.subject.pre_registration_confirmed',
				"Thank you for pre-registering for #{@conference.title}",
				:vars => {:conference_title => @conference.title}
			) : _(
				'email.subject.registration_confirmed',
				"Thank you for registering for #{@conference.title}",
				:vars => {:conference_title => @conference.title}
			)
		mail to: @user.named_email, subject: @subject
	end

	def broadcast(host, subject, content, user, conference)
		@host = host
		@content = content
		@banner = nil#(@host || 'http://localhost/') + (conference ? (conference.poster.preview.url || '') : image_url('logo.png'))
		@subject = "[#{conference ? conference.title : 'Bike!Bike!'}] #{subject}"
		if user && user.named_email
			email = user.named_email
			mail to: email, subject: @subject
		end
	end

	def workshop_facilitator_request(workshop, requester, message)
		@workshop = workshop
		@requester = requester
		addresses = []
		@workshop.active_facilitators.each do |f|
			addresses << f.named_email
		end
		@message = message
		@conference = Conference.find(@workshop.conference_id)
		@subject = _('email.subject.workshop_facilitator_request',
			 		"Request to facilitate #{@workshop.title} from #{@requester.name}",
			 		:vars => {:workshop_title => @workshop.title, :requester_name => @requester.firstname})
		mail to: addresses, reply_to: addresses + [@requester.named_email], subject: @subject
	end

	def workshop_facilitator_request_approved(workshop, user)
		@workshop = workshop
		@conference = Conference.find(@workshop.conference_id)
		@user = user
		@subject = (_'email.subject.workshop_request_approved',
					"You have been added as a facilitator of #{@workshop.title}",
					:vars => {:workshop_title => @workshop.title})
		mail to: user.named_email, subject: @subject
	end

	def workshop_facilitator_request_denied(workshop, user)
		@workshop = workshop
		@conference = Conference.find(@workshop.conference_id)
		@user = user
		@subject = (_'email.subject.workshop_request_denied',
					"Your request to facilitate #{@workshop.title} has been denied",
					:vars => {:workshop_title => @workshop.title})
		mail to: user.named_email, subject: @subject
	end

	def workshop_translated(workshop, data, locale, user, translator)
		@workshop = workshop
		@data = data
		@locale = locale
		@locale_name = language_name(locale)
		@user = user
		@translator = translator
		@subject = (_'email.subject.workshop_translated',
					"The #{@locale_name} translation for #{@workshop.title} has been modified",
					vars: {language: @language_name, workshop_title: @workshop.title})
		@data.each do |field, values|
			diff = Diffy::Diff.new(values[:old], values[:new])
			@data[field][:diff] = {
				text: diff.to_s(:text),
				html: diff.to_s(:html)
			}
		end

		@wrapper_id = :full_width

		mail to: user.named_email, subject: @subject
	end

	def workshop_original_content_changed(workshop, data, user, translator)
		@workshop = workshop
		@data = data
		@user = user
		@translator = translator
		@subject = (_'email.subject.workshop_original_content_changed',
					"Original content for #{@workshop.title} has been modified",
					vars: {workshop_title: @workshop.title})
		@data.each do |field, values|
			diff = Diffy::Diff.new(values[:old], values[:new])
			@data[field][:diff] = {
				text: diff.to_s(:text),
				html: diff.to_s(:html)
			}
		end

		@wrapper_id = :full_width

		mail to: user.named_email, subject: @subject
	end

	def error_report(subject, message, report, exception, request, params, user)
		@subject = subject
		@message = message
		@report = report
		@exception = exception
		@request = request
		@params = params
		@user = user
		mail to: 'goodgodwin@hotmail.com', subject: @subject
	end

	private
	def set_host(*args)
		if Rails.env.production?
			@host = "https://#{I18n.locale.to_s}.bikebike.org"
		elsif Rails.env.preview?
			@host = "https://preview-#{I18n.locale.to_s}.bikebike.org"
		else
			@host = UserMailer.default_url_options[:host]
		end
	end
end
