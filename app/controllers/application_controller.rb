class ApplicationController < BaseController
  protect_from_forgery with: :exception, :except => [:do_confirm, :js_error, :admin_update]

  before_filter :application_setup
  after_filter  :capture_page_info

  helper_method :protect, :policies

  def default_url_options
    { host: "#{request.protocol}#{request.host_with_port}", trailing_slash: true }
  end

  def capture_page_info
    capture_response unless @user_type == :potential_bot || @user_type == :bot
  end

  def capture_response(response_code = nil)
    Request.create(
      request_id: request.uuid,
      session_id: session.id,
      application: :bikebike,
      response: (response_code || response.code || 0).to_i,
      data: {
        user: logged_in? ? current_user.id : nil,
        params: @original_params || params,
        remote_ip: request.remote_ip,
        request_method: request.method,
        url: request.original_url,
        user_agent: request.user_agent,
        language: request.env['HTTP_ACCEPT_LANGUAGE'],
        cookies: request.env['HTTP_COOKIE'],
        requested_with: request.env['HTTP_X_REQUESTED_WITH']
      })

    @error_reports.each { |report| report_on(report) } if @error_reports
  end

  def report_on(report)
    return if Rails.env.development? || Rails.env.test?
    send_mail(:error_report, report.signature)
  end

  def application_setup
    if request.user_agent =~ /Googlebot/
      @user_type = :bot
    elsif request.url =~ /^.*\.php(\?.*)?$/
      @user_type = :potential_bot
    else
      @user_type = :normal
    end

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
    @stylesheets ||= Set.new
    # add the translations stylesheet if translating
    @stylesheets << params[:controller] if params[:controller] == 'translations'

    @_inline_scripts ||= Set.new
    @_inline_scripts << File.read(File.join(Rails.public_path, ActionController::Base.helpers.asset_path('main.js')))

    ActionMailer::Base.default_url_options = {
        host: "#{request.protocol}#{request.host_with_port}"
      }

    @alt_lang_urls = {}
    I18n.backend.enabled_locales.sort.each do |locale|
      locale = locale.to_s
      @alt_lang_urls[locale] = view_context.url_for_locale(locale) # don't show the current locale
    end

    # give each environment a different icon and theme colour so that we can easily see where we are. See https://css-tricks.com/give-development-domain-different-favicon-production
    @favicon = Rails.env.development? || Rails.env.preview? ? "favicon-#{Rails.env.to_s}.ico" : 'favicon.ico'
    @theme_colour = Rails.env.preview? ? '#EF57B4' : (Rails.env.development? ? '#D89E59' : '#00ADEF')
  end

  def home
    if @conference.present? && @conference.id.present?
      @workshops = Workshop.where(conference_id: @conference.id)

      if @conference.workshop_schedule_published
        @event_dlg = true
        get_scheule_data(false)
      end
    end
  end

  def policy
    @is_policy_page = true
  end

  def confirmation_sent(user)
    template = 'login_confirmation_sent'
    @page_title ||= 'page_titles.403.Please_Check_Email'

    if (request.present? && request.referrer.present? && conference = /^\/conferences\/(\w+)\/register\/?$/.match(request.referrer.gsub(/^https?:\/\/.*?\//, '/')))
      @this_conference = Conference.find_by!(slug: conference[1])
      @banner_image = @this_conference.cover_url
      template = 'conferences/email_confirm'
    end

    do_403 template
  end

  def locale_not_enabled!(locale = nil)
    locale_not_available!(locale)
  end
  
  def locale_not_available
    locale_not_available!(params[:locale])
  end
  
  def locale_not_available!(locale = nil)
    set_default_locale
    @original_params = params.clone
    params[:_original_action] = params[:action]
    params[:action] = 'error-locale-not-available'
    @page_title = 'page_titles.404.Locale_Not_Available'
    @main_title_vars = { vars: { language: view_context.language_name(locale) } }
    @main_title = 'error.locale_not_available.title'
    
    unless @alt_lang_urls.present?
      @alt_lang_urls = {}
      I18n.backend.enabled_locales.sort.each do |locale|
        locale = locale.to_s
        @alt_lang_urls[locale] = view_context.url_for_locale(locale) # don't show the current locale
      end
    end
    
    render 'application/locale_not_available', status: 404
  end

  def on_error(report, exception = nil)
    @error_reports ||= []
    @error_reports << report
    logger.info report.backtrace

    raise exception if exception.present? && Rails.env.development?
  end

  def js_error
    stack = params[:stack] || "#{params[:message]}\n\tat #{params[:url] || params[:location]}:#{params[:line]}:#{params[:col]}"
    requests = Request.where(session_id: session.id).order("created_at DESC")
    on_error(
      Report.create(
        request_id: requests.first.request_id,
        signature: params[:message],
        severity: :error,
        source: :javascript,
        backtrace: stack))

    render json: {}
  end

  unless Rails.env.test?
    rescue_from StandardError do |exception|
      handle_exception exception

      # show the error page
      error_500 exception
    end
  end

  def handle_exception(exception)
    # remove memory location from anonymous classes so tat we have a common signature
    classMatcher = /#<(.*?):0x[0-9a-f]+>/
    message = exception.message
    message.gsub!(classMatcher, '\1') while message =~ classMatcher
    stack = ([message] + exception.backtrace).join("\n  ")

    on_error(
      Report.create(
        request_id: request.uuid,
        signature: message,
        severity: :error,
        source: :application,
        backtrace: stack), exception)
  end

  def i18n_exception(str, exception, locale, key)
    message = "#{exception.class.name}: #{exception.to_s}"
    stack = "#{message}\n  #{caller.join("\n  ")}"
    on_error(
      Report.create(
        request_id: request.uuid,
        signature: message,
        severity: :error,
        source: :i18n,
        backtrace: stack))
  end

  def protect(&block)
    begin
      yield
    rescue Exception => exception
      handle_exception exception
    end
  end

  def contact
    @main_title = @page_title = 'page_titles.contact.Contact_Us'
  end

  def contact_send
    email_list = ['Godwin <goodgodwin@hotmail.com>']
    
    if params[:reason] == 'conference' && logged_in?

      @conference.conference_administrators.each do |administrator|
        email_list << administrator.user.named_email
      end
    end

    request_info = {
        'remote_ip'    => request.remote_ip,
        'uuid'         => request.uuid,
        'original_url' => request.original_url,
        'env'          => Hash.new
      }
    request.env.each do |key, value|
      request_info['env'][key.to_s] = value.to_s
    end

    send_delayed_mail(:contact,
        current_user || params[:email],
        params[:subject],
        params[:message],
        email_list
      )

    send_delayed_mail(:contact_details,
        current_user || params[:email],
        params[:subject],
        params[:message],
        request_info,
        params
      )

    redirect_to contact_sent_path
  end

  def contact_sent
    @main_title = @page_title = 'page_titles.contact.Contact_Us'
    @sent = true
    render 'contact'
  end

  def confirm_user
    if params[:email]
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

      do_403 template
    else
      do_404
    end
  end

  def error_404(args = {})
    @original_params = params.clone
    params[:_original_action] = params[:action]
    params[:action] = 'error-404'
    @page_title = 'page_titles.404.Page_Not_Found'
    @main_title = 'error.404.title'
    super(args)
  end

  def do_403(template = nil)
    @banner_image = 'grafitti.jpg'
    
    unless current_user
      @page_title = 'page_titles.403.Please_Login'
    end

    @template = template
    @page_title ||= 'page_titles.403.Access_Denied'
    @main_title ||= @page_title
    @original_params = params.clone
    params[:_original_action] = params[:action]
    params[:action] = 'error-403'

    super(template)
  end

  def error_500(exception = nil)
    @page_title = 'page_titles.500.An_Error_Occurred'
    @main_title = 'error.500.title'
    @original_params = params.clone
    params[:_original_action] = params[:action]
    params[:action] = 'error-500'
    @exception = exception

    super(exception)
    capture_response(500)
  end

  def on_translation_change(object, data, locale, translator_id)
    translator = User.find(translator_id)
    mailer = "#{object.class.table_name.singularize}_translated"

    if object.respond_to?(:get_translators)
      object.get_translators(data, locale).each do |id, user|
        if user.id != current_user.id && user.id != translator_id
          LinguaFranca.with_locale user.locale do
            send_delayed_mail(:send, mailer, object.id, data, locale, user.id, translator.id)
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
          LinguaFranca.with_locale user.locale do
            send_delayed_mail(:send, mailer, object.id, data, user.id, current_user.id)
          end
        end
      end
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

    @workshop_blocks.each_with_index do |info, block|
      info['days'].each do |block_day|
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

    @workshops.each do |workshop|
      if workshop.block.present?
        block = @workshop_blocks[workshop.block['block'].to_i]

        day_diff = workshop.block['day'].to_i - day_1
        day_diff += 7 if day_diff < 0
        day = (conference.start_date + day_diff.days).to_date

        if block.present? && @schedule[day].present? && @schedule[day][:times].present? && @schedule[day][:times][block['time'].to_f].present?
          @schedule[day][:times][block['time'].to_f][:item][:workshops][workshop.event_location_id] = { workshop: workshop, status: { errors: [], warnings: [], conflict_score: nil } }
          @schedule[day][:locations][workshop.event_location_id] ||= workshop.event_location if workshop.event_location.present?
        end
      end
    end

    @meals.each do |time, meal|
      day = meal['day'].to_date
      time = meal['time'].to_f
      @schedule[day] ||= {}
      @schedule[day][:times] ||= {}
      @schedule[day][:times][time] ||= {}
      @schedule[day][:times][time][:type] = :meal
      @schedule[day][:times][time][:length] = (meal['length'] || 1.0).to_f
      @schedule[day][:times][time][:item] = meal
    end

    @events.each do |event|
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
    @schedule.each do |day, data|
      @schedule[day][:times] = data[:times].sort.to_h
    end

    @schedule.each do |day, data|
      last_event = nil
      data[:times].each do |time, time_data|
        if last_event.present?
          @schedule[day][:times][last_event][:next_event] = time
        end
        last_event = time
      end
      @schedule[day][:num_locations] = (data[:locations] || []).size
    end

    @schedule.deep_dup.each do |day, data|
      data[:times].each do |time, time_data|
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

    @schedule.each do |day, data|
      @schedule[day][:times] = data[:times].sort.to_h
      @schedule[day][:locations] ||= {}

      # sort the locations by name      
      @schedule[day][:locations] = @schedule[day][:locations].sort_by { |event_id, event| event.present? ? event.title.downcase   : '' }.to_h
      # add an empty block if no workshops are scheduled on this day yet
      @schedule[day][:locations][0] = :add if do_analyze || @schedule[day][:locations].empty?

      if do_analyze
        data[:times].each do |time, time_data|
          if time_data[:type] == :workshop && time_data[:item].present? && time_data[:item][:workshops].present?
            ids = time_data[:item][:workshops].keys
            (0..ids.length).each do |i|
              if time_data[:item][:workshops][ids[i]].present?
                workshop_i = time_data[:item][:workshops][ids[i]][:workshop]
                conflicts = {}
                
                (i+1..ids.length).each do |j|
                  workshop_j = time_data[:item][:workshops][ids[j]].present? ? time_data[:item][:workshops][ids[j]][:workshop] : nil
                  if workshop_i.present? && workshop_j.present?
                    workshop_i.active_facilitators.each do |facilitator_i|
                      workshop_j.active_facilitators.each do |facilitator_j|
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

                needs.each do |need|
                  @schedule[day][:times][time][:item][:workshops][ids[i]][:status][:errors] << {
                      name: :need_not_available,
                      need: need,
                      location: location,
                      workshop: workshop_i,
                      i18nVars: {
                        need: I18n.t("workshop.options.amenity.#{need}"),
                        location: location.title,
                        workshop_title: workshop_i.title
                      }
                    } unless amenities.include? need
                end

                # collect common interested users
                interests = []
                (0..ids.length).each do |j|
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
      set_conference_registration
      raise ActiveRecord::PremissionDenied unless @registration.present?
    end

    def ensure_registration_is_complete!
      set_conference_registration!
      raise ActiveRecord::PremissionDenied unless @registration.registered?
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

    # send the confirmation email and make sure it get sent as quickly as possible
    def send_confirmation(confirmation)
      send_mail(:email_confirmation, confirmation.id)
    end

    def send_delayed_mail(*args)
      if Rails.env.preview? || Rails.env.production?
        UserMailer.delay(queue: Rails.env.to_s).send(*args)
      else
        UserMailer.send(*args).deliver_now
      end
    end

    def send_mail(*args)
      UserMailer.send(*args).deliver_now
    end

    def policies
      [
        :commitment,
        :respect,
        :empowerment,
        :accessible,
        :peaceful,
        :spaces,
        :hearing,
        :intent,
        :open_minds,
        :learning
      ]
    end
end
