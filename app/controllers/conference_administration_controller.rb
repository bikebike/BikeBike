require 'geocoder/calculations'
require 'rest_client'

class ConferenceAdministrationController < ApplicationController
  def administration
    set_conference
    return do_403 unless @this_conference.host? current_user
    @page_title_vars = { title: @this_conference.title }
  end

  def administration_step(step = nil)
    # get the step name
    method_step = step || params[:step]
    sub_step = view_context.administration_sub_steps[method_step]
    @admin_step = sub_step.present? ? sub_step : method_step

    # determine which method we will try to call
    method_name = "administrate_#{method_step}"

    # make sure the step exists, the conference exists, and the user has access to the page
    return do_404 unless self.respond_to? method_name, true
    set_conference
    return do_403 unless @this_conference.host? current_user

    @page_title_vars = { title: @this_conference.title }

    # set the page title
    @main_title = @page_title = 'articles.conference_registration.headings.Conference_Administration'
    @page_title_vars = { title: @this_conference.title }
    @main_title_vars = { vars: @page_title_vars }

    @admin_group = view_context.get_administration_group(@admin_step)

    set_flash_messages

    # call the step method
    self.send(method_name)

    # only render if we're coming from somewhere else
    render 'administration_step' if step.present?
  end

  def edit_event
    administration_step(:event_edit)
  end

  def edit_location
    administration_step(:location_edit)
  end

  def admin_update
    # get the step name
    @admin_step = params[:step]
    # determine which method we will try to call
    method_name = "admin_update_#{@admin_step}"

    # make sure the step exists, the conference exists, and the user has access to the page
    return do_404 unless self.respond_to? method_name, true
    set_conference
    return do_403 unless @this_conference.host? current_user

    set_flash_messages

    # redirect to the step unless the method handled redirection itself
    case self.send(method_name)
    when true
      administration_step(@admin_step)
    when false
      redirect_to administration_step_path(@this_conference.slug, @admin_step)
    end
  end

  def previous_stats
    set_conference
    conference = Conference.find_by_slug(params[:conference_slug])
    return do_403 unless conference.is_public
    get_stats(false, nil, conference)
    logger.info "Generating #{conference.slug}.xls"
    return respond_to do |format|
      format.xlsx { render xlsx: '../conferences/stats', filename: "stats-#{conference.slug}" }
    end
  end

  rescue_from ActiveRecord::PremissionDenied do |exception|
    do_403
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    do_404
  end

  private
    # Administration form pages
    def administrate_administrators
      @organizations = Organization.find_by_city(@this_conference.city_id)
    end

    def administrate_dates
      if @this_conference.start_date.present?
        @start_month = @this_conference.start_date.month
        @start_day = @this_conference.start_date.day
      end

      if @this_conference.end_date.present?
        @end_month = @this_conference.end_date.month
        @end_day = @this_conference.end_date.day
      end
    end

    def administrate_description
    end

    def administrate_group_ride
    end

    def administrate_poster
    end

    def administrate_broadcast
      if @this_conference.start_date.blank? || @this_conference.end_date.blank?
        @warning_message = :no_date_warning
      end
    end

    def administrate_broadcast_sent
    end

    def administrate_providers
      @conditions = Conference.default_provider_conditions.deep_merge(
        @this_conference.provider_conditions || {})
    end

    def administrate_payment_message
    end

    def administrate_housing_info
    end

    def administrate_workshop_info
    end

    def administrate_schedule_info
    end

    def administrate_travel_info
    end

    def administrate_city_info
    end

    def administrate_what_to_bring
    end

    def administrate_volunteering_info
    end

    def administrate_additional_details
    end

    def administrate_suggested_amounts
    end

    def administrate_paypal
    end

    def administrate_registration_status
      if @this_conference.start_date.blank? || @this_conference.end_date.blank?
        @warning_message = :no_date_warning
      end
    end

    def administrate_organizations
      @organizations = Organization.all

      if request.format.xlsx?
        logger.info "Generating organizations.xls"
        @excel_data = {
          columns: [:name, :street_address, :city, :subregion, :country, :postal_code, :email, :phone, :status],
          keys: {
              name: 'forms.labels.generic.name',
              street_address: 'forms.labels.generic.street_address',
              city: 'forms.labels.generic.city',
              subregion: 'forms.labels.generic.subregion',
              country: 'forms.labels.generic.country',
              postal_code: 'forms.labels.generic.postal_code',
              email: 'forms.labels.generic.email',
              phone: 'forms.labels.generic.phone',
              status: 'forms.labels.generic.status'
            },
          data: [],
        }
        @organizations.each do |org|
          if org.present?
            address = org.locations.first
            @excel_data[:data] << {
              name: org.name,
              street_address: address.present? ? address.street : nil,
              city: address.present? ? address.city : nil,
              subregion: address.present? ? I18n.t("geography.subregions.#{address.country}.#{address.territory}") : nil,
              country: address.present? ? I18n.t("geography.countries.#{address.country}") : nil,
              postal_code: address.present? ? address.postal_code : nil,
              email: org.email_address,
              phone: org.phone,
              status: org.status
            }
          end
        end
        return respond_to do |format|
          format.xlsx { render xlsx: '../conferences/stats', filename: "organizations" }
        end
      end
    end

    def administrate_registrations
      if @this_conference.start_date.blank? || @this_conference.end_date.blank?
        @warning_message = :no_date_warning
        return
      end

      get_stats(!request.format.xlsx?)

      if request.format.xlsx?
        logger.info "Generating stats.xls"
        return respond_to do |format|
          format.xlsx { render xlsx: '../conferences/stats', filename: "stats-#{DateTime.now.strftime('%Y-%m-%d')}" }
        end
      end

      @registration_count = @registrations.size
      @completed_registrations = 0
      @bikes = 0
      @donation_count = 0
      @donations = 0
      @food = { meat: 0, vegan: 0, vegetarian: 0, all: 0 }
      @registrations.each do |r|
        if view_context.registration_status(r) == :registered
          @completed_registrations += 1

          @bikes += 1 if r.bike == 'yes'

          if r.food.present?
            @food[r.food.to_sym] += 1
            @food[:all] += 1
          end

          if r.registration_fees_paid.present? && r.registration_fees_paid > 0
            @donation_count += 1
            @donations += r.registration_fees_paid
          end
        end
      end
    end

    def administrate_stats
      if @this_conference.start_date.blank? || @this_conference.end_date.blank?
        @warning_message = :no_date_warning
        return
      end

      get_stats(!request.format.xlsx?)

      if request.format.xlsx?
        logger.info "Generating stats.xls"
        return respond_to do |format|
          format.xlsx { render xlsx: '../conferences/stats', filename: "stats-#{DateTime.now.strftime('%Y-%m-%d')}" }
        end
      else
        @registration_count = @registrations.size
        @completed_registrations = 0
        @bikes = 0
        @donation_count = 0
        @donations = 0
        @food = { meat: 0, vegan: 0, vegetarian: 0, all: 0 }
        @registrations.each do |r|
          if view_context.registration_status(r) == :registered
            @completed_registrations += 1

            @bikes += 1 if r.bike == 'yes'

            if r.food.present?
              @food[r.food.to_sym] += 1
              @food[:all] += 1
            end

            if r.registration_fees_paid.present? && r.registration_fees_paid > 0
              @donation_count += 1
              @donations += r.registration_fees_paid
            end
          end
        end

        @past_conferences = []
        Conference.all.order("start_date DESC").each do |conference|
          @past_conferences << conference if conference.is_public && @this_conference.id != conference.id
        end
      end
    end

    def administrate_housing
      # do a full analysis
      analyze_housing
      
      if request.format.xlsx?
        logger.info "Generating housing.xls"
        @excel_data = {
          columns: [:name, :phone, :street_address, :email, :availability, :considerations, :empty, :empty, :empty, :guests],
          keys: {
              name: 'forms.labels.generic.name',
              street_address: 'forms.labels.generic.street_address',
              email: 'forms.labels.generic.email',
              phone: 'forms.labels.generic.phone',
              availability: 'articles.conference_registration.headings.host.availability',
              considerations: 'articles.conference_registration.headings.host.considerations'
            },
          column_types: {
              name: :bold,
              guests: :table
            },
          data: [],
        }
        @hosts.each do |id, host|
          data = (host.housing_data || {})
          host_data = {
            name: host.user.name,
            street_address: data['address'],
            email: host.user.email,
            phone: data['phone'],
            availability: data['availability'].present? && data['availability'][1].present? ? view_context.date_span(data['availability'][0].to_date, data['availability'][1].to_date) : '',
            considerations: ((data['considerations'] || []).map { |consideration| view_context._"articles.conference_registration.host.considerations.#{consideration}" }).join(', '),
            empty: '',
            guests: {
              columns: [:name, :area, :email, :arrival_departure, :allergies, :food, :companion, :city],
              keys: {
                name: 'forms.labels.generic.name',
                area: 'articles.workshops.headings.space',
                email: 'forms.labels.generic.email',
                arrival_departure: 'articles.admin.housing.headings.arrival_departure',
                companion: 'forms.labels.generic.companion',
                city: 'forms.labels.generic.city',
                food: 'forms.labels.generic.food',
                allergies: 'forms.labels.generic.allergies'
              },
              column_types: {
                name: :bold
              },
              data: []
            }
          }

          @housing_data[id][:guests].each do |space, space_data|
            space_data.each do |guest_id, guest_data|
              guest = guest_data[:guest]
              if guest.present?
                companion = view_context.companion(guest)

                host_data[:guests][:data] << {
                  name: guest.user.name,
                  area: (view_context._"forms.labels.generic.#{space}"),
                  email: guest.user.email,
                  arrival_departure: guest.arrival.present? && guest.departure.present? ? view_context.date_span(guest.arrival.to_date, guest.departure.to_date) : '',
                  companion: companion.present? ? (companion.is_a?(User) ? companion.name : (view_context._"articles.conference_registration.terms.registration_status.#{companion}")) : '',
                  city: guest.city,
                  food: guest.food.present? ? (view_context._"articles.conference_registration.questions.food.#{guest.food}") : '',
                  allergies: guest.allergies
                }
              end
            end
          end

          @excel_data[:data] << host_data
        end
        return respond_to do |format|
          format.xlsx { render xlsx: '../conferences/stats', filename: "housing" }
        end
      end
    end

    def administrate_locations
      @locations = EventLocation.where(:conference_id => @this_conference.id)
    end

    def administrate_events
      @event = Event.new(locale: I18n.locale)
      @events = Event.where(:conference_id => @this_conference.id)
      @day = nil
      @time = nil
      @length = 1.5
    end

    def administrate_event_edit
      @event = Event.find_by!(conference_id: @this_conference.id, id: params[:id])
      @day = @event.start_time.midnight
      @time = view_context.hour_span(@day, @event.start_time)
      @length = view_context.hour_span(@event.start_time, @event.end_time)
    end

    def administrate_location_edit
      @location = EventLocation.find_by!(conference_id: @this_conference.id, id: params[:id])
      @space = @location.space.present? ? @location.space.to_sym : nil
      @amenities = @location.amenities.present? ? JSON.parse(@location.amenities).map(&:to_sym) : nil
    end

    def administrate_meals
      @meals = Hash[(@this_conference.meals || {}).map{ |k, v| [k.to_i, v] }].sort.to_h
    end

    def administrate_workshop_times
      get_block_data
      @workshop_blocks << {
        'time' => nil,
        'length' => 1.0,
        'days' => []
      }
    end

    def administrate_schedule
      @can_edit = true
      @entire_page = true
      get_scheule_data
    end

    def administrate_publish_schedule
    end

    def get_stats(html_format = false, id = nil, conference = @this_conference)
      @registrations = ConferenceRegistration.where(conference_id: conference.id).sort { |a,b| (a.user.present? ? (a.user.firstname || '') : '').downcase <=> (b.user.present? ? (b.user.firstname || '') : '').downcase }
      @excel_data = {
        columns: [
            :name,
            :email,
            :status,
            :is_attending,
            :is_subscribed,
            :registration_fees_paid,
            :date,
            :city,
            :preferred_language
          ] +
          User.AVAILABLE_LANGUAGES.map { |l| "language_#{l}".to_sym } +
          [ 
            :arrival,
            :departure,
            :housing,
            :bike,
            :food,
            :companion,
            :companion_email,
            :other,
            :can_provide_housing,
            :first_day,
            :last_day,
            :address,
            :phone
          ] + ConferenceRegistration.all_spaces +
          ConferenceRegistration.all_considerations + [
            :notes
          ],
        column_types: {
            name: :bold,
            date: :datetime,
            email: :email,
            companion_email: :email,
            arrival: [:date, :day],
            departure: [:date, :day],
            registration_fees_paid: :money,
            other: :text,
            first_day: [:date, :day],
            last_day: [:date, :day],
            notes: :text
          },
        keys: {
            name: 'forms.labels.generic.name',
            email: 'forms.labels.generic.email',
            status: 'forms.labels.generic.registration_status',
            is_attending: 'articles.conference_registration.terms.is_attending',
            is_subscribed: 'articles.user_settings.headings.email_subscribe',
            city: 'forms.labels.generic.event_location',
            date: 'articles.conference_registration.terms.Date',
            preferred_language: 'articles.conference_registration.terms.Preferred_Languages',
            arrival: 'forms.labels.generic.arrival',
            departure: 'forms.labels.generic.departure',
            housing: 'forms.labels.generic.housing',
            bike: 'forms.labels.generic.bike',
            food: 'forms.labels.generic.food',
            companion: 'articles.conference_registration.terms.companion',
            companion_email: 'articles.conference_registration.terms.companion_email',
            registration_fees_paid: 'articles.conference_registration.headings.fees_paid',
            other: 'forms.labels.generic.other_notes',
            can_provide_housing: 'articles.conference_registration.can_provide_housing',
            first_day: 'forms.labels.generic.first_day',
            last_day: 'forms.labels.generic.last_day',
            notes: 'forms.labels.generic.notes',
            phone: 'forms.labels.generic.phone',
            address: 'forms.labels.generic.address',
            contact_info: 'articles.conference_registration.headings.contact_info',
            questions: 'articles.conference_registration.headings.questions',
            hosting: 'articles.conference_registration.headings.hosting'
          },
        data: []
      }

      if conference.id != @this_conference.id
        @excel_data[:columns] -= [:name, :email]
      end

      User.AVAILABLE_LANGUAGES.each do |l|
        @excel_data[:keys]["language_#{l}".to_sym] = "languages.#{l.to_s}" 
      end
      ConferenceRegistration.all_spaces.each do |s|
        @excel_data[:column_types][s] = :number
        @excel_data[:keys][s] = "forms.labels.generic.#{s.to_s}"
      end
      ConferenceRegistration.all_considerations.each do |c|
        @excel_data[:keys][c] = "articles.conference_registration.host.considerations.#{c.to_s}"
      end
      @registrations.each do |r|
        user = r.user_id ? User.where(id: r.user_id).first : nil
        if user.present?
          companion = view_context.companion(r)
          companion = companion.is_a?(User) ? companion.name : (view_context._"articles.conference_registration.terms.registration_status.#{companion}") if companion.present?
          steps = r.steps_completed || []

          if id.nil? || id == r.id
            housing_data = r.housing_data || {}
            availability = housing_data['availability'] || []
            availability[0] = Date.parse(availability[0]) if availability[0].present?
            availability[1] = Date.parse(availability[1]) if availability[1].present?

            data = {
              id: r.id,
              name: user.firstname || '',
              email: user.email || '',
              status: (view_context._"articles.conference_registration.terms.registration_status.#{view_context.registration_status(r)}"),
              is_attending: (view_context._"articles.conference_registration.questions.bike.#{r.is_attending == 'n' ? 'no' : 'yes'}"),
              is_subscribed: user.is_subscribed == false ? (view_context._'articles.conference_registration.questions.bike.no') : '',
              date: r.created_at ? r.created_at.strftime("%F %T") : '',
              city: r.city || '',
              preferred_language: user.locale.present? ? (view_context.language_name user.locale) : '',
              arrival: r.arrival ? r.arrival.strftime("%F %T") : '',
              departure: r.departure ? r.departure.strftime("%F %T") : '',
              housing: r.housing.present? ? (view_context._"articles.conference_registration.questions.housing.#{r.housing}") : '',
              bike: r.bike.present? ? (view_context._"articles.conference_registration.questions.bike.#{r.bike}") : '',
              food: r.food.present? ? (view_context._"articles.conference_registration.questions.food.#{r.food}") : '',
              companion: companion,
              companion_email: (housing_data['companion'] || { 'email' => ''})['email'],
              registration_fees_paid: r.registration_fees_paid,
              other: r.allergies.present? ? "#{r.allergies}\n\n#{r.other}" : r.other,
              can_provide_housing: r.can_provide_housing ? (view_context._'articles.conference_registration.questions.bike.yes') : '',
              first_day: availability[0].present? ? availability[0].strftime("%F %T") : '',
              last_day: availability[1].present? ? availability[1].strftime("%F %T") : '',
              notes: housing_data['notes'],
              address: housing_data['address'],
              phone: housing_data['phone'],
              raw_values: {
                housing: r.housing,
                bike: r.bike,
                food: r.food,
                arrival: r.arrival.present? ? r.arrival.to_date : nil,
                departure: r.departure.present? ? r.departure.to_date : nil,
                preferred_language: user.locale,
                is_attending: r.is_attending != 'n',
                is_subscribed: user.is_subscribed,
                can_provide_housing: r.can_provide_housing,
                first_day: availability[0].present? ? availability[0].to_date : nil,
                last_day: availability[1].present? ? availability[1].to_date : nil
              },
              html_values: {
                date: r.created_at.present? ? r.created_at.strftime("%F %T") : '',
                arrival: r.arrival.present? ? view_context.date(r.arrival.to_date, :span_same_year_date_1) : '',
                departure: r.departure.present? ? view_context.date(r.departure.to_date, :span_same_year_date_1) : '',
                first_day: availability[0].present? ? view_context.date(availability[0].to_date, :span_same_year_date_1) : '',
                last_day: availability[1].present? ? view_context.date(availability[1].to_date, :span_same_year_date_1) : ''
              }
            }
            User.AVAILABLE_LANGUAGES.each do |l|
              can_speak = ((user.languages || []).include? l.to_s)
              data["language_#{l}".to_sym] = (can_speak ? (view_context._'articles.conference_registration.questions.bike.yes') : '')
              data[:raw_values]["language_#{l}".to_sym] = can_speak
            end
            ConferenceRegistration.all_spaces.each do |s|
              space = (housing_data['space'] || {})[s.to_s]
              data[s] = space.present? ? space.to_i : nil
            end
            ConferenceRegistration.all_considerations.each do |c|
              consideration = (housing_data['considerations'] || []).include?(c.to_s)
              data[c] = (consideration ? (view_context._'articles.conference_registration.questions.bike.yes') : '')
              data[:raw_values][c] = consideration
            end
            @excel_data[:data] << data
          end
        end
      end

      if html_format
        yes_no = [
              [(view_context._"articles.conference_registration.questions.bike.yes"), true],
              [(view_context._"articles.conference_registration.questions.bike.no"), false]
            ]
        @column_options = {
          housing: ConferenceRegistration.all_housing_options.map { |h| [
            (view_context._"articles.conference_registration.questions.housing.#{h}"),
            h] },
          bike: ConferenceRegistration.all_bike_options.map { |b| [
            (view_context._"articles.conference_registration.questions.bike.#{b}"),
            b] },
          food: ConferenceRegistration.all_food_options.map { |f| [
            (view_context._"articles.conference_registration.questions.food.#{f}"),
            f] },
          arrival: view_context.conference_days_options_list(:before_plus_one),
          departure: view_context.conference_days_options_list(:after_minus_one),
          preferred_language: I18n.backend.enabled_locales.map { |l| [
              (view_context.language_name l), l
            ] },
          is_attending: [yes_no.first],
          is_subscribed: [yes_no.last],
          can_provide_housing: yes_no,
          first_day: view_context.conference_days_options_list(:before),
          last_day: view_context.conference_days_options_list(:after)
        }
        User.AVAILABLE_LANGUAGES.each do |l|
          @column_options["language_#{l}".to_sym] = [
              [(view_context._"articles.conference_registration.questions.bike.yes"), true]
            ]
        end
        ConferenceRegistration.all_considerations.each do |c|
          @column_options[c.to_sym] = [
              [(view_context._"articles.conference_registration.questions.bike.yes"), true]
            ]
        end
      end
    end

    def get_housing_data
      @hosts = {}
      @guests = {}
      ConferenceRegistration.where(:conference_id => @this_conference.id).each do |registration|
        if registration.can_provide_housing
          @hosts[registration.id] = registration
        elsif registration.housing.present? && registration.housing != 'none'
          @guests[registration.id] = registration
        end
      end
    end

    def analyze_housing
      get_housing_data unless @hosts.present? && @guests.present?

      @housing_data = {}
      @hosts_affected_by_guests = {}
      @hosts.each do |id, host|
        @hosts[id].housing_data ||= {}
        @housing_data[id] = { guests: {}, space: {} }
        @hosts[id].housing_data['space'] ||= {}
        @hosts[id].housing_data['space'].each do |s, size|
          size = (size || 0).to_i
          @housing_data[id][:guests][s.to_sym] = {}
          @housing_data[id][:space][s.to_sym] = size
        end
      end
      
      @guests_housed = 0

      @guests.each do |guest_id, guest|
        data = guest.housing_data || {}
        @hosts_affected_by_guests[guest_id] ||= []

        if data['host']
          @guests_housed += 1
          host_id = (data['host'].present? ? data['host'].to_i : nil)
          host = host_id.present? ? @hosts[host_id] : nil

          # make sure the host was found and that they are still accepting guests
          if host.present? && host.can_provide_housing
            @hosts_affected_by_guests[guest_id] << host_id

            space = (data['space'] || :bed).to_sym

            @housing_data[host_id] ||= {}
            host_data = host.housing_data
            unless @housing_data[host_id][:guests][space].present?
              @housing_data[host_id][:guests][space] ||= {}
              @housing_data[host_id][:space][space] ||= 0
            end

            @housing_data[host_id][:guests][space][guest_id] = { guest: guest }

            @housing_data[host_id][:guest_data] ||= {}
            @housing_data[host_id][:guest_data][guest_id] = { warnings: {}, errors: {} }

            @housing_data[host_id][:guest_data][guest_id][:warnings][:dates] = {} unless view_context.available_dates_match?(host, guest)

            if (guest.housing == 'house' && space == :tent) ||
              (guest.housing == 'tent' && (space == :bed_space || space == :floor_space))
              @housing_data[host_id][:guest_data][guest_id][:warnings][:space] = { actual: (view_context._"forms.labels.generic.#{space.to_s}"), expected: (view_context._"articles.conference_registration.questions.housing.#{guest.housing}")}
            end

            if data['companion'].present?
              companion = if data['companion']['id'].present?
                            User.find(data['companion']['id'])
                          else
                            User.find_user(data['companion']['email'])
                          end

              if companion.present?
                reg = ConferenceRegistration.find_by(
                    user_id: companion.id,
                    conference_id: @this_conference.id
                  )
                if reg.present? && @guests[reg.id].present?
                  housing_data = reg.housing_data || {}
                  companion_host = housing_data['host'].present? ? housing_data['host'].to_i : nil
                  @hosts_affected_by_guests[guest_id] << companion_host
                  if companion_host != host_id && reg.housing.present? && reg.housing != 'none'
                    # set this as an error if the guest has selected only one other to stay with, but if they have requested to stay with more, make this only a warning
                    @housing_data[host_id][:guest_data][guest_id][:warnings][:companions] = { name: "<strong>#{reg.user.name}</strong>".html_safe, id: reg.id }
                  end
                end
              end
            end
          else
            # make sure the housing data is empty if the host wasn't found, just in case something happened to the host
            @guests[guest_id].housing_data ||= {}
            @guests[guest_id].housing_data['host'] = nil
            @guests[guest_id].housing_data['space'] = nil
          end
        end
      end
      
      @hosts.each do |id, host|
        host_data = host.housing_data

        @hosts[id].housing_data['space'].each do |space, size|
          # make sure the host isn't overbooked
          space = space.to_sym
          space_available = (size || 0).to_i
          @housing_data[id][:warnings] ||= {}
          @housing_data[id][:warnings][:space] ||= {}
          @housing_data[id][:warnings][:space][space] ||= []

          if @housing_data[id][:guests][space].size > space_available
            @housing_data[id][:warnings][:space][space] << :overbooked
          end
        end
      end

      return @hosts_affected_by_guests
    end

    # Administration update endpoints

    def admin_update_administrators
      case params[:button]
      when 'add_org_member'
        # add this user to the organization
        organization = Organization.find(params[:org_id].to_i)

        # make sure the organization is a host of the conference before adding a member
        if @this_conference.host_organization?(organization)
          organization.users << (User.get params[:email])
          organization.save
          set_success_message :org_member_added
        else
          set_error_message :error_adding_org_member
        end
      when 'remove_org_member'
        organization = Organization.find(params[:org_id].to_i)
        user = User.find(params[:user_id].to_i)
        if !user.present? || !@this_conference.host_organization?(organization) || (user.id == current_user.id && !current_user.administrator?)
          set_error_message :error_removing_org_member
        else
          organization.users -= [user]
          organization.save
          set_success_message :org_member_removed
        end
      when 'add_administrator'
        begin
          @this_conference.administrators << (User.get params[:email])
          @this_conference.save
          set_success_message :administrator_added
        rescue
          set_error_message :error_adding_administrator
        end
      when 'remove_administrator'
        begin
          user = User.find(params[:user_id].to_i)
          if !user.present? || (user.id == current_user.id && !current_user.administrator?)
            set_error_message :error_removing_administrator
          else
            @this_conference.administrators -= [user]
            @this_conference.save
            set_success_message :administrator_removed
          end
        rescue
          set_error_message :error_removing_administrator
        end
      when 'set_organizations'
        begin
          @this_conference.organizations = params[:organizations].keys.map { |id| Organization.find(id) }
          @this_conference.save
          set_success_message @admin_step
        rescue
          set_error_message(@admin_step)
        end
      else
        do_404
        return true
      end

      return false
    end

    def admin_update_dates
      begin
        start_date = DateTime.new(@this_conference.conference_year, params[:start_month].to_i, params[:start_day].to_i)
      rescue
        set_error_message(@admin_step)
        return false
      end
      
      begin
        end_date = DateTime.new(@this_conference.conference_year, params[:end_month].to_i, params[:end_day].to_i)
      rescue
        set_error(:end_date, :error)
        return false
      end

      if start_date > end_date
        set_error(:start_date, :start_date_after_end_date)
        return false
      end

      @this_conference.start_date = start_date
      @this_conference.end_date = end_date

      set_success_message @admin_step
      @this_conference.save
      return false
    end

    def admin_update_description
      params[:info].each do |locale, value|
        @this_conference.set_column_for_locale(:info, locale, html_value(value))
      end
      @this_conference.save
      set_success_message @admin_step
      return false
    end

    def admin_update_group_ride
      params[:group_ride_info].each do |locale, value|
        @this_conference.set_column_for_locale(:group_ride_info, locale, html_value(value))
      end
      @this_conference.save
      set_success_message @admin_step
      return false
    end

    def admin_update_housing_info
      params[:housing_info].each do |locale, value|
        @this_conference.set_column_for_locale(:housing_info, locale, html_value(value))
      end
      @this_conference.save
      set_success_message @admin_step
      return false
    end

    def admin_update_workshop_info
      params[:workshop_info].each do |locale, value|
        @this_conference.set_column_for_locale(:workshop_info, locale, html_value(value))
      end
      @this_conference.save
      set_success_message @admin_step
      return false
    end

    def admin_update_schedule_info
      params[:schedule_info].each do |locale, value|
        @this_conference.set_column_for_locale(:schedule_info, locale, html_value(value))
      end
      @this_conference.save
      set_success_message @admin_step
      return false
    end

    def admin_update_travel_info
      params[:travel_info].each do |locale, value|
        @this_conference.set_column_for_locale(:travel_info, locale, html_value(value))
      end
      @this_conference.save
      set_success_message @admin_step
      return false
    end

    def admin_update_city_info
      params[:city_info].each do |locale, value|
        @this_conference.set_column_for_locale(:city_info, locale, html_value(value))
      end
      @this_conference.save
      set_success_message @admin_step
      return false
    end

    def admin_update_what_to_bring
      params[:what_to_bring].each do |locale, value|
        @this_conference.set_column_for_locale(:what_to_bring, locale, html_value(value))
      end
      @this_conference.save
      set_success_message @admin_step
      return false
    end

    def admin_update_volunteering_info
      params[:volunteering_info].each do |locale, value|
        @this_conference.set_column_for_locale(:volunteering_info, locale, html_value(value))
      end
      @this_conference.save
      set_success_message @admin_step
      return false
    end

    def admin_update_additional_details
      params[:additional_details].each do |locale, value|
        @this_conference.set_column_for_locale(:additional_details, locale, html_value(value))
      end
      @this_conference.save
      set_success_message @admin_step
      return false
    end

    def admin_update_poster
      begin
        @this_conference.poster = params[:poster]
        @this_conference.save
        set_success_message @admin_step
      rescue
        set_error_message(@admin_step)
      end
      return false
    end

    def admin_update_payment_message
      begin
        params[:payment_message].each do |locale, value|
          @this_conference.set_column_for_locale(:payment_message, locale, html_value(value))
        end
        @this_conference.save
        set_success_message @admin_step
      rescue
        set_error_message(@admin_step)
      end
      
      return false
    end

    def admin_update_suggested_amounts
      begin
        @this_conference.payment_amounts = ((params[:payment_amounts] || {}).values.map &:to_i) - [0]
        @this_conference.save
        set_success_message @admin_step
      rescue
        set_error_message(@admin_step)
      end

      return false
    end

    def admin_update_paypal
      begin
        @this_conference.paypal_email_address = params[:paypal_email_address]
        @this_conference.paypal_username = params[:paypal_username]
        @this_conference.paypal_password = params[:paypal_password]
        @this_conference.paypal_signature = params[:paypal_signature]
        @this_conference.save
        set_success_message @admin_step
      rescue
        set_error_message(@admin_step)
      end

      return false
    end

    def admin_update_registration_status
      begin
        @this_conference.registration_status = params[:registration_status]
        @this_conference.save
        set_success_message @admin_step
      rescue
        set_error_message(@admin_step)
      end

      return false
    end

    def admin_update_registrations
      if params[:button] == 'save' || params[:button] == 'update'
        if params[:button] == 'save'
          return do_404 unless params[:email].present? && params[:name].present?

          user = User.get(params[:email])
          user.firstname = params[:name]
          user.save!
          registration = ConferenceRegistration.new(
              conference:      @this_conference,
              user_id:         user.id,
              steps_completed: []
            )
        else
          registration = ConferenceRegistration.where(
                id: params[:key].to_i,
                conference_id: @this_conference.id
              ).limit(1).first
        end

        user_changed = false
        params.each do |key, value|
          case key.to_sym
          when :city
            if value.present?
              city = City.search(value)
              if city.present?
                registration.city_id = city.id
              end
            end
          when :housing, :bike, :food, :allergies, :other
            registration.send("#{key.to_s}=", value)
          when :registration_fees_paid
            registration.registration_fees_paid = value.to_i
          when :can_provide_housing
            registration.send("#{key.to_s}=", value.present?)
          when :arrival, :departure
            registration.send("#{key.to_s}=", value.present? ? Date.parse(value) : nil)
          when :companion_email
            registration.housing_data ||= {}
            registration.housing_data['companion'] ||= {}
            registration.housing_data['companion']['email'] = value
            registration.housing_data['companion']['id'] = User.find_user(value)
          when :preferred_language
            registration.user.locale = value
            user_changed = true
          when :is_subscribed
            registration.user.is_subscribed = (value != "false")
            user_changed = true
          when :is_attending
            registration.is_attending = value.present? ? 'y' : 'n'
          when :first_day
            registration.housing_data ||= {}
            registration.housing_data['availability'] ||= []
            registration.housing_data['availability'][0] = value
          when :last_day
            registration.housing_data ||= {}
            registration.housing_data['availability'] ||= []
            registration.housing_data['availability'][1] = value
          when :address, :phone, :notes
            registration.housing_data ||= {}
            registration.housing_data[key.to_s] = value
          else
            if key.start_with?('language_')
              l = key.split('_').last
              if User.AVAILABLE_LANGUAGES.include? l.to_sym
                registration.user.languages ||= []
                if value.present?
                  registration.user.languages |= [l]
                else
                  registration.user.languages -= [l]
                end
                user_changed = true
              end
            elsif ConferenceRegistration.all_considerations.include? key.to_sym
              registration.housing_data ||= {}
              registration.housing_data['considerations'] ||= []
              if value.present?
                registration.housing_data['considerations'] |= [key]
              else
                registration.housing_data['considerations'] -= [key]
              end
            elsif ConferenceRegistration.all_spaces.include? key.to_sym
              registration.housing_data ||= {}
              registration.housing_data['space'] ||= {}
              registration.housing_data['space'][key.to_s] = value
            end
          end
        end
        registration.user.save! if user_changed
        registration.save!

        # do the normal thing if this wasn't an ajax request        
        return false if params[:button] == 'save'
        
        get_stats(true, params[:key].to_i) 
        options = view_context.registrations_table_options
        options[:html] = true
        
        render html: view_context.excel_rows(@excel_data, {}, options)
      else
        do_404
      end

      return true
    end

    def admin_update_housing
      # modify the guest data
      if params[:button] == 'get-guest-list'
        analyze_housing
        render partial: 'select_guest_table', locals: { host: @hosts[params['host'].to_i], space: params['space'] }
      elsif params[:button] == 'set-guest'
        guest = ConferenceRegistration.where(
            id: params[:guest].to_i,
            conference_id: @this_conference.id
          ).limit(1).first

        guest.housing_data ||= {}
        guest.housing_data['space'] = params[:space]
        guest.housing_data['host'] = params[:host].to_i
        guest.save!
        
        analyze_housing

        render partial: 'hosts_table'
      elsif params[:button] == 'remove-guest'
        guest = ConferenceRegistration.where(
            id: params[:guest].to_i,
            conference_id: @this_conference.id
          ).limit(1).first

        guest.housing_data ||= {}
        guest.housing_data.delete('space')
        guest.housing_data.delete('host')
        guest.save!
        
        analyze_housing

        render partial: 'hosts_table'
      else
        do_404
      end

      return nil
    end

    def admin_update_broadcast
      @hide_description = true
      @subject = params[:subject]
      @body = params[:body]
      @send_to = params[:send_to]
      @register_template = :administration
      if params[:button] == 'send'
        view_context.broadcast_to(@send_to).each do |user|
          send_mail(:broadcast,
              "#{request.protocol}#{request.host_with_port}",
              @subject,
              @body,
              user.id,
              @this_conference.id
            )
        end
        redirect_to administration_step_path(@this_conference.slug, :broadcast_sent)
        return true
      elsif params[:button] == 'preview'
        @send_to_count = view_context.broadcast_to(@send_to).size
        @broadcast_step = :preview
      elsif params[:button] == 'test'
        @broadcast_step = :test
        send_mail(:broadcast,
            "#{request.protocol}#{request.host_with_port}",
            @subject,
            @body,
            current_user.id,
            @this_conference.id
          )
        @send_to_count = view_context.broadcast_to(@send_to).size
      end
      return false
    end

    def admin_update_locations
      case params[:button]
      when 'save'
        location = EventLocation.find_by! id: params[:id].to_i, conference_id: @this_conference.id
        empty_param = get_empty(params, [:title, :address, :space])
        if empty_param.present?
          flash[:warning] = (view_context._"errors.messages.fields.#{empty_param.to_s}.empty")
        else
          location.title = params[:title]
          location.address = params[:address]
          location.amenities = (params[:needs] || {}).keys.to_json
          location.space = params[:space]
          location.save!
        end
      when 'cancel'
        # just go back to where we were
      when 'delete'
        location = EventLocation.find_by! id: params[:id].to_i, conference_id: @this_conference.id
        location.destroy
      when 'create'
        empty_param = get_empty(params, [:title, :address, :space])
        if empty_param.present?
          flash[:warning] = (view_context._"errors.messages.fields.#{empty_param.to_s}.empty")
        else
          EventLocation.create(
              conference_id: @this_conference.id,
              title: params[:title],
              address: params[:address],
              amenities: (params[:needs] || {}).keys.to_json,
              space: params[:space]
            )
        end
      else
        do_404
      end

      return false
    end

    def admin_update_meals
      case params[:button]
      when 'add_meal'
        @this_conference.meals ||= {}
        @this_conference.meals[(Date.parse(params[:day]) + params[:time].to_f.hours).to_time.to_i] = {
          title: params[:title],
          info: params[:info],
          location: params[:event_location],
          day: params[:day],
          time: params[:time]
        }
        @this_conference.save!
        return false
      when 'delete'
        @this_conference.meals ||= {}
        @this_conference.meals.delete params[:meal]
        @this_conference.save!
        return false
      end

      do_404
      return true
    end

    def admin_update_events
      case params[:button]
      when 'edit'
        redirect_to edit_event_path(@this_conference.slug, params[:id])
        return true
      when 'save'
        if params[:id].present?
          event = Event.find_by!(conference_id: @this_conference.id, id: params[:id])
        else
          event = Event.new(conference_id: @this_conference.id, locale: I18n.locale)
        end
        
        # save schedule data
        event.event_location_id = params[:event_location]
        event.start_time = Date.parse(params[:day]) + params[:time].to_f.hours
        event.end_time = event.start_time + params[:time_span].to_f.hours

        # save translations
        (params[:info] || {}).each do |locale, value|
          event.set_column_for_locale(:title, locale, html_value(value), current_user.id) unless value = event._title(locale)
        end

        (params[:title] || {}).each do |locale, value|
          event.set_column_for_locale(:info, locale, value, current_user.id) unless value = event._info(locale)
        end

        event.save

        return false
      when 'cancel'
        return false
      end

      do_404
      return true
    end
    
    def admin_update_workshop_times
      case params[:button]
      when 'save_block'
        empty_param = empty_params(:time, :time_span, :days)
        if empty_param.present?
          set_error_message "save_block_#{empty_param}_required".to_sym
        else
          @this_conference.workshop_blocks ||= []
          @this_conference.workshop_blocks[params[:workshop_block].to_i] = {
            'time' => params[:time],
            'length' => params[:time_span],
            'days' => params[:days].keys
          }
          @this_conference.save
          set_success_message :block_saved
        end
        return false
      when 'delete_block'
        @this_conference.workshop_blocks ||= []
        @this_conference.workshop_blocks.delete_at(params[:workshop_block].to_i)
        @this_conference.save
        set_success_message :block_deleted
        return false
      end

      do_404
      return nil
    end

    def admin_update_publish_schedule
      case params[:button]
      when 'publish'
        @this_conference.workshop_schedule_published = !@this_conference.workshop_schedule_published
        @this_conference.save
        set_success_message "schedule_#{@this_conference.workshop_schedule_published ? '' : 'un'}published".to_sym
        return false
      end

      do_404
      return false
    end

    def admin_update_schedule
      case params[:button]
      when 'deschedule_workshop'
        workshop = Workshop.find_by!(conference_id: @this_conference.id, id: params[:id])
        workshop.event_location_id = nil
        workshop.block = nil
        workshop.save!
        @can_edit = true
        @entire_page = false
        get_scheule_data
        render partial: 'schedule'
      when 'get-workshop-list'
        get_scheule_data(true)
        
        @ordered_workshops = {}
        @block = params[:block].to_i
        @time = @workshop_blocks[@block]['time'].to_f
        @day = (Date.parse params[:day])
        @location = params[:location]
        @event_location = @location.present? && @location.to_i > 0 ? EventLocation.find(@location.to_i) : nil

        @workshops.sort { |a, b| a.title.downcase <=> b.title.downcase }.each do |workshop|
          @ordered_workshops[workshop.id] = workshop
        end

        render partial: 'select_workshop_table'
      when 'set-workshop'
        workshop = Workshop.find_by!(conference_id: @this_conference.id, id: params[:workshop].to_i)
        workshop.event_location_id = params[:location]
        workshop.block = { day: (Date.parse params[:day]).wday, block: params[:block] }
        workshop.save!

        @can_edit = true
        @entire_page = false
        get_scheule_data
        
        render partial: 'schedule'
      else
        do_404
      end

      return nil
    end

    def admin_update_providers
      case params[:button]
      when 'save_distance'
        @this_conference.provider_conditions ||= Conference.default_provider_conditions
        @this_conference.provider_conditions['distance'] = {
          'number' => params[:distance_number],
          'unit' => params[:distance_unit]
        }
        @this_conference.save
        set_success_message :distance_saved
        return false
      end

      do_404
      return false
    end

    def get_empty(hash, keys)
      keys = [keys] unless keys.is_a?(Array)
      keys.each do |key|
        return key unless hash[key].present?
      end
      return nil
    end

    def empty_params(*args)
      get_empty(params, args)
    end
end
