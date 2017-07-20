require 'diffy'

class UserMailer < ActionMailer::Base
  include LinguaFrancaHelper
  add_template_helper(ApplicationHelper)

  before_filter :set_host

  default from: "Bike!Bike! <info@bikebike.org>"

  def email_confirmation(confirmation)
    @confirmation = EmailConfirmation.find_by_id(confirmation) if confirmation.present?
    if @confirmation.present?
      I18n.locale = @confirmation.user.locale if @confirmation.user.locale.present?
      mail to: @confirmation.user.named_email, subject: clean_subject(_'email.subject.confirm_email','Please confirm your email address')
    end
  end

  def registration_confirmation(registration)
    @registration = ConferenceRegistration.find(registration) if registration.present?
    @conference = @registration.conference
    @user = @registration.user
    I18n.locale = @user.locale if @user.locale.present?
    subject = @conference.registration_status.to_sym == :pre ?
      _(
        'email.subject.pre_registration_confirmed',
        "Thank you for pre-registering for #{@conference.title}",
        vars: {conference_title: @conference.title}
      ) : _(
        'email.subject.registration_confirmed',
        "Thank you for registering for #{@conference.title}",
        vars: {conference_title: @conference.title}
      )
    mail to: @user.named_email, subject: clean_subject(subject)
  end

  def broadcast(host, subject, content, user, conference)
    @host = host
    @content = content
    @banner = nil
    @conference = Conference.find(conference) if conference.present?
    @user = User.find(user) if user.present?
    if @user && @user.named_email
      mail to: @user.named_email, subject: clean_subject("[#{@conference ? @conference.title : 'Bike!Bike!'}] #{subject}")
    end
  end

  def workshop_facilitator_request(workshop, requester, message)
    @workshop = Workshop.find(workshop) if workshop.present?
    @requester = User.find(requester) if requester.present?
    addresses = []
    I18n.locale = @workshop.active_facilitators.first.locale if @workshop.active_facilitators.first.locale.present?
    @workshop.active_facilitators.each do |f|
      addresses << f.named_email
    end
    @message = message
    @conference = Conference.find(@workshop.conference_id)
    subject = ActionView::Base.full_sanitizer.sanitize(_('email.subject.workshop_facilitator_request', vars: { workshop_title: @workshop.title, requester_name: @requester.firstname }))
    mail to: addresses, reply_to: addresses + [@requester.named_email], subject: clean_subject(subject)
  end

  def workshop_facilitator_request_approved(workshop, user)
    @workshop = Workshop.find(workshop) if workshop.present?
    @conference = Conference.find(@workshop.conference_id)
    @user = User.find(user) if user.present?
    I18n.locale = @user.locale if @user.locale.present?
    mail to: @user.named_email, subject: clean_subject(_('email.subject.workshop_request_approved', vars: { workshop_title: @workshop.title }))
  end

  def workshop_facilitator_request_denied(workshop, user)
    @workshop = Workshop.find(workshop) if workshop.present?
    @conference = @workshop.conference
    @user = User.find(user) if user.present?
    I18n.locale = @user.locale if @user.present? && @user.locale.present?
    mail to: @user.named_email, subject: clean_subject(_'email.subject.workshop_request_denied', vars: { workshop_title: @workshop.title })
  end

  def workshop_translated(workshop, data, locale, user, translator)
    @workshop = Workshop.find(workshop) if workshop.present?
    @data = data
    @locale = locale
    @locale_name = language_name(locale)
    @user = User.find(user) if user.present?
    I18n.locale = @user.locale if @user.present? && @user.locale.present?
    @translator = User.find(translator) if translator.present?

    @wrapper_id = :full_width

    mail to: @user.named_email, subject: clean_subject(_'email.subject.workshop_translated', vars: { language: @language_name, workshop_title: @workshop.title })
  end

  def workshop_original_content_changed(workshop, data, user, translator)
    @workshop = Workshop.find(workshop) if workshop.present?
    @data = data
    @user = User.find(user) if user.present?
    I18n.locale = @user.locale if @user.present? && @user.locale.present?
    @translator = User.find(translator) if translator.present?
    @data.each do |field, values|
      diff = Diffy::Diff.new(values[:old], values[:new])
      @data[field][:diff] = {
        text: diff.to_s(:text),
        html: diff.to_s(:html)
      }
    end

    @wrapper_id = :full_width

    mail to: @user.named_email, subject: clean_subject(_'email.subject.workshop_original_content_changed', vars: { workshop_title: @workshop.title })
  end

  def workshop_comment(workshop, comment, user)
    @workshop = Workshop.find(workshop) if workshop.present?
    @comment = Comment.find(comment) if comment.present?
    @user = User.find(user) if user.present?
    I18n.locale = @user.locale if @user.present? && @user.locale.present?

    subject = if @comment.reply?
                (_'email.subject.workshop_comment.reply', vars: { user_name: @comment.user.name })
              else
                (_'email.subject.workshop_comment.comment', vars: { user_name: @comment.user.name, workshop_title: @workshop.title })
              end

    mail to: @user.named_email, subject: clean_subject(subject)
  end

  def error_report(report_signature)
    @reports = Report.where(signature: report_signature).order('created_at DESC')
    @report = @reports.first

    return unless @report.present?

    @title = case @report.source.to_sym
              when :javascript
                "JavaScript fatal report"
              when :i18n
                "Missing translation report"
              else
                "Fatal report"
              end
    subject = "#{@title}: #{report_signature}"

    @request = Request.find_by_request_id(@report.request_id)

    return unless @request.present?

    @user = User.find(@request.data['user'].to_i) if @request.data['user'].present?

    mail to: administrators, subject: clean_subject(subject)
  end

  def contact(from, subject, message, email_list)
    @message = message
    @from = from.is_a?(Integer) ? User.find(from) : from

    mail to: email_list.join(', '), subject: clean_subject(subject), reply_to: @from.is_a?(User) ? @from.named_email : @from
  end

  def contact_details(from, subject, message, request, params)
    @message = message
    @from = from.is_a?(Integer) ? User.find(from) : from
    @request = request
    @params = params

    mail to: 'goodgodwin@hotmail.com', subject: clean_subject("Details for: \"#{subject}\"")
  end

  def server_startup(environment)
    @environment = environment
    mail to: 'goodgodwin@hotmail.com', subject: clean_subject("Deployment to #{environment} complete")
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
    default_url_options[:host] = @host
  end

  def clean_subject(subject)
    subject = ActionView::Base.full_sanitizer.sanitize(subject) unless Rails.env.test?
    @subject = subject
    return subject
  end

  def administrators
    User.where(role: :administrator).map(&:named_email).join(',')
  end
end
