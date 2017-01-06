module ActiveRecord
  class PremissionDenied < RuntimeError
  end
end

class ApplicationController < LinguaFrancaApplicationController
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception, :except => [:do_confirm, :js_error, :admin_update]

  before_filter :capture_page_info

  helper_method :protect

  @@test_host
  @@test_location

  def capture_page_info
    if request.method == "GET" && (params[:controller] != 'application' || params[:action] != 'contact')
      session[:last_request]
      request_info = {
        'params' => params,
        'request' => {
          'remote_ip'    => request.remote_ip,
          'uuid'         => request.uuid,
          'original_url' => request.original_url,
          'env'          => Hash.new
        }
      }
      request.env.each do | key, value |
        request_info['request']['env'][key.to_s] = value.to_s
      end
      session['request_info'] = request_info
    end
    # set the translator to the current user if we're logged in
    I18n.config.translator = current_user
    I18n.config.callback = self

    # get the current conferences and set them globally
    status_hierarchy = {
      open: 1,
      pre: 2,
      closed: 3
    }
    @conferences = Conference.where(is_featured: true, is_public: true).order("start_date DESC").sort do |a, b|
      status_hierarchy[(a.registration_status || :closed).to_sym] <=> status_hierarchy[(b.registration_status || :closed).to_sym]
    end

    # set the top conference
    @conference = @conferences.first

    # add some style sheets
    @stylesheets ||= Array.new
    # add the translations stylesheet if translating
    @stylesheets << params[:controller] if params[:controller] == 'translations'

    @_inline_scripts ||= []
    @_inline_scripts << Rails.application.assets.find_asset('main.js').to_s

    ActionMailer::Base.default_url_options = {:host => "#{request.protocol}#{request.host_with_port}"}

    if request.post? && params[:action] == 'do_confirm'
      halt_redirection!
    end

    @alt_lang_urls = {}
    I18n.backend.enabled_locales.each do |locale|
      locale = locale.to_s
      @alt_lang_urls[locale] = view_context.url_for_locale(locale) # don't show the current locale
    end

    # give each environment a different icon and theme colour so that we can easily see where we are. See https://css-tricks.com/give-development-domain-different-favicon-production
    @favicon = Rails.env.development? || Rails.env.preview? ? "favicon-#{Rails.env.to_s}.ico" : 'favicon.ico'
    @theme_colour = Rails.env.preview? ? '#EF57B4' : (Rails.env.development? ? '#D89E59' : '#00ADEF')

    # call the base method to detect the language
    super
  end

  def home
    @workshops = Workshop.where(:conference_id => @conference.id)

    if @conference.workshop_schedule_published
      @event_dlg = true
      get_scheule_data(false)
    end
  end

  def policy
    @is_policy_page = true
  end

  def robots
    render :text => File.read("config/robots-#{Rails.env.production? ? 'live' : 'dev'}.txt"), :content_type => 'text/plain'
  end

  def humans
    render :text => File.read("config/humans.txt"), :content_type => 'text/plain'
  end

  def self.set_host(host)
    @@test_host = host
  end

  def self.set_location(location)
    @@test_location = location
  end

  def self.get_location()
    @@test_location
  end

  def do_404
    error_404(status: 404)
  end

  def error_404(args = {})
    params[:_original_action] = params[:action]
    params[:action] = 'error-404'
    @page_title = 'page_titles.404.Page_Not_Found'
    @main_title = 'error.404.title'
    render 'application/404', args
  end

  def do_403(template = nil)
    @template = template
    @page_title ||= 'page_titles.403.Access_Denied'
    @main_title ||= @page_title
    params[:_original_action] = params[:action]
    params[:action] = 'error-403'
    render 'application/permission_denied', status: 403
  end

  def error_500(exception = nil)
    @page_title = 'page_titles.500.An_Error_Occurred'
    @main_title = 'error.500.title'
    params[:_original_action] = params[:action]
    params[:action] = 'error-500'
    render 'application/500', status: 500
  end

  def js_error
    # send and email if this is production
    report = "A JavaScript error has occurred on <code>#{params[:location]}</code>"
    if params[:location] == params[:url]
      report += " on line <code>#{params[:lineNumber]}</code>"
    else
      report += " in <code>#{params[:url]}:#{params[:lineNumber]}</code>"
    end

    begin
      # log the error
      logger.info "Javascript exception: #{params[:message]}"

      UserMailer.send_mail(:error_report) do 
        [
          "A JavaScript error has occurred",
          report,
          params[:message],
          nil,
          request,
          params,
          current_user,
          Time.now.strftime("%d/%m/%Y %H:%M")
        ]
      end# if Rails.env.preview? || Rails.env.production?
    rescue Exception => exception2
      logger.info exception2.to_s
      logger.info exception2.backtrace.join("\n")
    end
    render json: {}
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    do_404
  end

  rescue_from ActiveRecord::PremissionDenied do |exception|
    do_403
  end

  rescue_from AbstractController::ActionNotFound do |exception|
    @banner_image = 'grafitti.jpg'
    
    if current_user
      @page_title = nil#'page_titles.Please_Login'
      do_403 'not_a_translator'
      #return
    else
      @page_title = 'page_titles.403.Please_Login'
      do_403 'translator_login'
    end
  end

  def locale_not_enabled!(locale = nil)
    locale_not_available!(locale)
  end
  
  def locale_not_available!(locale = nil)
    set_default_locale
    params[:_original_action] = params[:action]
    params[:action] = 'error-locale-not-available'
    @page_title = 'page_titles.404.Locale_Not_Available'
    @main_title_vars = { vars: { language: view_context.language_name(locale) } }
    @main_title = 'error.locale_not_available.title'
    render 'application/locale_not_available', status: 404
  end

  rescue_from StandardError do |exception|
    handle_exception exception

    # show the error page
    error_500 exception
  end

  def handle_exception(exception)
    # log the error
    logger.info exception.to_s
    logger.info exception.backtrace.join("\n")

    # send and email if this is production
    suppress(Exception) do
      UserMailer.send_mail(:error_report) do 
        [
          "An error has occurred in #{Rails.env}",
          nil,
          exception.to_s,
          exception.backtrace.join("\n"),
          request,
          params,
          current_user,
          Time.now.strftime("%d/%m/%Y %H:%M")
        ]
      end if Rails.env.preview? || Rails.env.production?
    end

    # raise the error if we are in development so that we can debug it
    raise exception if Rails.env.development?
  end

  def protect(&block)
    begin
      yield
    rescue Exception => exception
      handle_exception exception
    end
  end

  def generate_confirmation(user, url, expiry = nil)
    if user.is_a? String
      user = User.find_by_email(user)

      # if the user doesn't exist, just show them a 403
      do_403 unless user.present?
    end
    expiry ||= (Time.now + 12.hours)
    session[:confirm_uid] = user.id

    unless user.locale.present?
      user.locale = I18n.locale
      user.save
    end

    # send the confirmation email and make sure it get sent as quickly as possible
    UserMailer.send_mail :email_confirmation do
      EmailConfirmation.create(user_id: user.id, expiry: expiry, url: url)
    end
  end

  def user_settings
    @conferences = Array.new
    if logged_in?
      Conference.all.each do | conference |
        @conferences << conference if conference.host? current_user
      end
    end
    @main_title = @page_title = 'page_titles.user_settings.Your_Account'
  end

  def contact
    @main_title = @page_title = 'page_titles.contact.Contact_Us'
  end

  def contact_send
    email_list = ['Godwin <goodgodwin@hotmail.com>']
    
    if params[:reason] == 'conference'

      @conference.organizations.each do | org |
        org.users.each do | user |
          email_list << user.named_email
        end
      end
    end

    UserMailer.send_mail(:contact) do 
      [
        current_user || params[:email],
        params[:subject],
        params[:message],
        email_list
      ]
    end

    request_info = session['request_info'] || { 'request' => request, 'params' => params }
    UserMailer.send_mail(:contact_details) do 
      [
        current_user || params[:email],
        params[:subject],
        params[:message],
        request_info['request'],
        request_info['params']
      ]
    end

    redirect_to contact_sent_path
  end

  def contact_sent
    @main_title = @page_title = 'page_titles.contact.Contact_Us'
    @sent = true
    render 'contact'
  end

  def update_user_settings
    return do_403 unless logged_in?
    current_user.firstname = params[:name]
    current_user.lastname = nil
    current_user.languages = (params[:languages] || { I18n.locale.to_s => true }).keys
    current_user.is_subscribed = params[:email_subscribe].present?
    current_user.save
    redirect_to settings_path
  end

  def do_confirm(settings = nil)
    settings ||= {:template => 'login_confirmation_sent'}
    if params[:email]
      # see if we've already sent the confirmation email and are just confirming
      #  the email address
      if params[:token]
        user = User.find_by_email(params[:email])
        confirm(user)
        return
      end
      user = User.find_by_email(params[:email])

      unless user.present?
        user = User.create(:email => params[:email], locale: I18n.locale)
      end

      # generate the confirmation, send the email and show the 403
      referrer = params[:dest] || (request.present? && request.referer.present? ? request.referer.gsub(/^.*?\/\/.*?\//, '/') : settings_path)
      generate_confirmation(params[:email], referrer)
      template = 'login_confirmation_sent'
      @page_title ||= 'page_titles.403.Please_Check_Email'

      if (request.present? && request.referrer.present? && conference = /^\/conferences\/(\w+)\/register\/?$/.match(request.referrer.gsub(/^https?:\/\/.*?\//, '/')))
        @this_conference = Conference.find_by!(slug: conference[1])
        @banner_image = @this_conference.cover_url
        template = 'conferences/email_confirm'
      end
    end
    
    if request.post?
      @banner_image ||= 'grafitti.jpg'
      @page_title ||= 'page_titles.403.Please_Login'

      do_403 (template || 'translator_login')
    else
      do_404
    end
  end

  def confirm(uid = nil)
    @confirmation = EmailConfirmation.find_by_token(params[:token])

    unless @confirmation.present?
      @token_not_found = true
      return do_404
    end

    confirm_user = nil
    if uid.is_a?(User)
      confirm_user = uid
      uid = confirm_user.id
    end
    # check to see if we were given a user id to confirm against
    #  if we were, make sure it was the same one
    if (uid ||= (params[:uid] || session[:confirm_uid]))
      if uid == @confirmation.user_id
        session[:uid] = nil
        confirm_user ||= User.find uid
        auto_login(confirm_user)
      else
        @confirmation.delete
      end

      redirect_to (@confirmation.url || '/')
      return
    end

    @banner_image = 'grafitti.jpg'
    @page_title = 'page_titles.403.Please_Confirm_Email'
    do_403 'login_confirm'
  end

  def translator_request
    @banner_image = 'grafitti.jpg'
    @page_title = 'page_titles.403.Translator_Request_Sent'
    do_403 'translator_request_sent'
  end

  def user_logout
    logout()
    redirect_to (params[:url] || '/')
  end

  def find_user
    user = User.find_user(params[:e])

    if user.present?
      return render json: {
        name: user.name,
        email: user.email,
        exists: true
      }
    end
    render json: {
        name: I18n.t('user.not_found'),
        email: nil,
        exists: false
      }
  end

  def login_user(u)
    auto_login(u)
  end

  def on_translation_change(object, data, locale, translator_id)
    translator = User.find(translator_id)
    mailer = "#{object.class.table_name.singularize}_translated"

    if object.respond_to?(:get_translators)
      object.get_translators(data, locale).each do |id, user|
        if user.id != current_user.id && user.id != translator_id
          UserMailer.send_mail mailer, user.locale do
            { :args => [object, data, locale, user, translator] }
          end
        end
      end
    end
  end

  def on_translatable_content_change(object, data)
    mailer = "#{object.class.table_name.singularize}_original_content_changed"
    
    if object.respond_to?(:get_translators)
      object.get_translators(data).each do |id, user|
        if user.id != current_user.id
          UserMailer.send_mail mailer, user.locale do
            { :args => [object, data, user, current_user] }
          end
        end
      end
    end
  end

  def i18n_exception(str, exception, locale, key)
    # log it
    logger.info "Missing translation found for: #{key}"

    # send and email if this is production
    begin
      UserMailer.send_mail(:error_report) do 
        [
          "A missing translation found in #{Rails.env}",
          "<p>A translation for <code>#{key}</code> in <code>#{locale.to_s}</code> was found. The text that was rendered to the user was:</p><blockquote>#{str || 'nil'}</blockquote>",
          exception.to_s,
          nil,
          request,
          params,
          current_user,
          Time.now.strftime("%d/%m/%Y %H:%M")
        ]
      end if Rails.env.preview? || Rails.env.production?
    rescue Exception => exception2
      logger.info exception2.to_s
      logger.info exception2.backtrace.join("\n")
    end
  end

  def set_success_message(message, is_ajax = false)
    if is_ajax
      @success_message = message
    else
      flash[:success_message] = message
    end
  end

  def set_error_message(message, is_ajax = false)
    if is_ajax
      @error_message = message
    else
      flash[:error_message] = message
    end
  end

  def set_error(field, error, is_ajax = false)
    if is_ajax
      @errors ||= {}
      @errors[field] = error
    else
      flash[:errors] ||= {}
      flash[:errors][field] = error
    end
  end

  def set_flash_messages
    @errors = flash[:errors] || {}
    @warnings = flash[:warning] || []
    @success_message = flash[:success_message]
    @error_message = flash[:error_message] || []
  end

  def get_block_data
    conference = @this_conference || @conference
    @workshop_blocks = conference.workshop_blocks || []
    @block_days = []
    day = conference.start_date
    while day <= conference.end_date
      @block_days << day.wday
      day += 1.day
    end
  end

  def get_scheule_data(do_analyze = true)
    conference = @this_conference || @conference
    @meals = Hash[(conference.meals || {}).map{ |k, v| [k.to_i, v] }].sort.to_h
    @events = Event.where(:conference_id => conference.id).order(start_time: :asc)
    @workshops = Workshop.where(:conference_id => conference.id).order(start_time: :asc)
    @locations = {}

    get_block_data

    @schedule = {}
    day_1 = conference.start_date.wday

    @workshop_blocks.each_with_index do | info, block |
      info['days'].each do | block_day |
        day_diff = block_day.to_i - day_1
        day_diff += 7 if day_diff < 0
        day = (conference.start_date + day_diff.days).to_date
        time = info['time'].to_f
        @schedule[day] ||= { times: {}, locations: {} }
        @schedule[day][:times][time] ||= {}
        @schedule[day][:times][time][:type] = :workshop
        @schedule[day][:times][time][:length] = info['length'].to_f
        @schedule[day][:times][time][:item] = { block: block, workshops: {} }
      end
    end

    @workshops.each do | workshop |
      if workshop.block.present?
        block = @workshop_blocks[workshop.block['block'].to_i]
        day_diff = workshop.block['day'].to_i - day_1
        day_diff += 7 if day_diff < 0
        day = (conference.start_date + day_diff.days).to_date

        if @schedule[day].present? && @schedule[day][:times].present? && @schedule[day][:times][block['time'].to_f].present?
          @schedule[day][:times][block['time'].to_f][:item][:workshops][workshop.event_location_id] = { workshop: workshop, status: { errors: [], warnings: [], conflict_score: nil } }
          @schedule[day][:locations][workshop.event_location_id] ||= workshop.event_location if workshop.event_location.present?
        end
      end
    end

    @meals.each do | time, meal |
      day = meal['day'].to_date
      time = meal['time'].to_f
      @schedule[day] ||= {}
      @schedule[day][:times] ||= {}
      @schedule[day][:times][time] ||= {}
      @schedule[day][:times][time][:type] = :meal
      @schedule[day][:times][time][:length] = (meal['length'] || 1.0).to_f
      @schedule[day][:times][time][:item] = meal
    end

    @events.each do | event |
      if event.present? && event.start_time.present? && event.end_time.present?
        day = event.start_time.midnight.to_date
        time = event.start_time.hour.to_f + (event.start_time.min / 60.0)
        @schedule[day] ||= {}
        @schedule[day][:times] ||= {}
        @schedule[day][:times][time] ||= {}
        @schedule[day][:times][time][:type] = :event
        @schedule[day][:times][time][:length] = (event.end_time - event.start_time) / 3600.0
        @schedule[day][:times][time][:item] = event
      end
    end

    @schedule = @schedule.sort.to_h
    @schedule.each do | day, data |
      @schedule[day][:times] = data[:times].sort.to_h
    end

    @schedule.each do | day, data |
      last_event = nil
      data[:times].each do | time, time_data |
        if last_event.present?
          @schedule[day][:times][last_event][:next_event] = time
        end
        last_event = time
      end
      @schedule[day][:num_locations] = (data[:locations] || []).size
    end

    @schedule.deep_dup.each do | day, data |
      data[:times].each do | time, time_data |
        if time_data[:next_event].present? || time_data[:length] > 0.5
          span = 0.5
          length = time_data[:next_event].present? ? time_data[:next_event] - time : time_data[:length]
          while span < length
            @schedule[day][:times][time + span] ||= {
              type: (span >= time_data[:length] ? :empty : :nil),
              length: 0.5
            }
            span += 0.5
          end
        end
      end
    end

    @schedule = @schedule.sort.to_h

    @schedule.each do | day, data |
      @schedule[day][:times] = data[:times].sort.to_h
      @schedule[day][:locations] ||= {}
      
      # add an empty block if no workshops are scheduled on this day yet
      @schedule[day][:locations][0] = :add if do_analyze || @schedule[day][:locations].empty?

      if do_analyze
        data[:times].each do | time, time_data |
          if time_data[:type] == :workshop && time_data[:item].present? && time_data[:item][:workshops].present?
            ids = time_data[:item][:workshops].keys
            (0..ids.length).each do | i |
              if time_data[:item][:workshops][ids[i]].present?
                workshop_i = time_data[:item][:workshops][ids[i]][:workshop]
                conflicts = {}
                
                (i+1..ids.length).each do | j |
                  workshop_j = time_data[:item][:workshops][ids[j]].present? ? time_data[:item][:workshops][ids[j]][:workshop] : nil
                  if workshop_i.present? && workshop_j.present?
                    workshop_i.active_facilitators.each do | facilitator_i |
                      workshop_j.active_facilitators.each do | facilitator_j |
                        if facilitator_i.id == facilitator_j.id
                          @schedule[day][:times][time][:status] ||= {}
                          @schedule[day][:times][time][:item][:workshops][ids[j]][:status][:errors] << {
                              name: :common_facilitator,
                              facilitator: facilitator_i,
                              workshop: workshop_i,
                              i18nVars: {
                                facilitator_name: facilitator_i.name,
                                workshop_title: workshop_i.title
                              }
                            }
                        end
                      end
                    end
                  end
                end

                location = workshop_i.event_location || EventLocation.new
                needs = JSON.parse(workshop_i.needs || '[]').map &:to_sym
                amenities = JSON.parse(location.amenities || '[]').map &:to_sym

                needs.each do | need |
                  @schedule[day][:times][time][:item][:workshops][ids[i]][:status][:errors] << {
                      name: :need_not_available,
                      need: need,
                      location: location,
                      workshop: workshop_i,
                      i18nVars: {
                        need: need.to_s,
                        location: location.title,
                        workshop_title: workshop_i.title
                      }
                    } unless amenities.include? need
                end

                # collect common interested users
                interests = []
                (0..ids.length).each do | j |
                  workshop_j = time_data[:item][:workshops][ids[j]].present? ? time_data[:item][:workshops][ids[j]][:workshop] : nil
                  if workshop_i.present? && workshop_j.present? && workshop_i.id != workshop_j.id
                    interests = interests | workshop_j.interested.map { | u | u.user_id }
                  end
                end

                @schedule[day][:times][time][:item][:workshops][ids[i]][:status][:conflict_score] = (interests & (workshop_i.interested.map { | u | u.user_id })).length
              end
            end
          end
        end
      end
    end
  end

  protected
    def set_conference
      @this_conference = Conference.find_by!(slug: params[:slug])
    end

    def set_conference_registration
      @registration = logged_in? ? ConferenceRegistration.find_by(user_id: current_user.id, conference_id: @this_conference.id) : nil
    end

    def set_conference_registration!
      @registration = set_conference_registration
      raise ActiveRecord::PremissionDenied unless @registration.present?
    end

    def set_or_create_conference_registration
      set_conference_registration
      return @registration if @registration.present?

      @registration ||= ConferenceRegistration.new(
          conference:      @this_conference,
          user_id:         current_user.id,
          steps_completed: []
        )
      last_registration_data = ConferenceRegistration.where(user_id: current_user.id).order(created_at: :desc).limit(1).first

      if last_registration_data.present?
        if last_registration_data['languages'].present? && current_user.languages.blank?
          current_user.languages = JSON.parse(last_registration_data['languages'])
          current_user.save!
        end
        
        @registration.city = last_registration_data.city if last_registration_data.city.present?
      end
    end

    # Set empty HTML values to nil, sometimes we will get values such as '<p> </p>' in rich edits, this will help to make sure they are actually empty
    def html_value(value)
      return value.present? && ActionView::Base.full_sanitizer.sanitize(value).strip.present? ? value : nil
    end
end
