require 'diffy'

class UserMailer < ActionMailer::Base
	add_template_helper(ApplicationHelper)
	include LinguaFrancaHelper

	before_filter :set_host

	default from: "Bike!Bike! <noreply@bikebike.org>"

	def email_confirmation(confirmation)
		@confirmation = EmailConfirmation.find(confirmation) if confirmation.present?
		@subject = _'email.subject.confirm_email','Please confirm your email address'
		mail to: @confirmation.user.named_email, subject: @subject
	end

	def registration_confirmation(registration)
		@registration = ConferenceRegistration.find(registration) if registration.present?
		@conference = @registration.conference
		@user = @registration.user
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
		@banner = nil
		@conference = Conference.find(conference) if conference.present?
		@user = User.find(user) if user.present?
		@subject = "[#{@conference ? @conference.title : 'Bike!Bike!'}] #{subject}"
		if @user && @user.named_email
			mail to: @user.named_email, subject: @subject
		end
	end

	def workshop_facilitator_request(workshop, requester, message)
		@workshop = Workshop.find(workshop) if workshop.present?
		@requester = User.find(requester) if requester.present?
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
		@workshop = Workshop.find(workshop) if workshop.present?
		@conference = Conference.find(@workshop.conference_id)
		@user = User.find(user) if user.present?
		@subject = (_'email.subject.workshop_request_approved',
					"You have been added as a facilitator of #{@workshop.title}",
					:vars => {:workshop_title => @workshop.title})
		mail to: @user.named_email, subject: @subject
	end

	def workshop_facilitator_request_denied(workshop, user)
		@workshop = Workshop.find(workshop) if workshop.present?
		@conference = @workshop.conference
		@user = User.find(user) if user.present?
		@subject = (_'email.subject.workshop_request_denied',
					"Your request to facilitate #{@workshop.title} has been denied",
					:vars => {:workshop_title => @workshop.title})
		mail to: @user.named_email, subject: @subject
	end

	def workshop_translated(workshop, data, locale, user, translator)
		@workshop = Workshop.find(workshop) if workshop.present?
		@data = data
		@locale = locale
		@locale_name = language_name(locale)
		@user = User.find(user) if user.present?
		@translator = User.find(translator) if translator.present?
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

		mail to: @user.named_email, subject: @subject
	end

	def workshop_original_content_changed(workshop, data, user, translator)
		@workshop = Workshop.find(workshop) if workshop.present?
		@data = data
		@user = User.find(user) if user.present?
		@translator = User.find(translator) if translator.present?
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

		mail to: @user.named_email, subject: @subject
	end

	def workshop_comment(workshop, comment, user)
		@workshop = Workshop.find(workshop) if workshop.present?
		@comment = Comment.find(comment) if comment.present?
		@user = User.find(user) if user.present?

		if @comment.reply?
			@subject = (_'email.subject.workshop_comment.reply', vars: { user_name: @comment.user.name })
		else
			@subject = (_'email.subject.workshop_comment.comment', vars: { user_name: @comment.user.name, workshop_title: @workshop.title })
		end

		mail to: @user.named_email, subject: @subject
	end

	def error_report(subject, message, report, exception, request, params, user)
		@subject = subject
		@message = message
		@report = report
		@exception = exception
		@request = request
		@params = params
		@user = User.find(user) if user.present?
		mail to: 'goodgodwin@hotmail.com', subject: @subject
	end

	def contact(from, subject, message, email_list)
		@message = message
		@subject = subject
		@from = from.is_a?(Integer) ? User.find(from) : from

		mail to: email_list.join(', '), subject: @subject, reply_to: @from.is_a?(User) ? @from.named_email : @from
	end

	def contact_details(from, subject, message, request, params)
		@message = message
		@subject = "Details for: \"#{subject}\""
		@from = from.is_a?(Integer) ? User.find(from) : from
		@request = request
		@params = params

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
