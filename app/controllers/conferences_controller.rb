require 'geocoder/calculations'
require 'rest_client'

class ConferencesController < ApplicationController
  def list
    @page_title = 'articles.conferences.headings.Conference_List'
    @conference_list = { future: [], passed: [] }
    Conference.all.order("start_date DESC").each do | conference |
      if conference.is_public || conference.host?(current_user)
        @conference_list[conference.over? ? :passed : :future] << conference
      end
    end
    @conference_list[:future].reverse!
  end

  def view
    set_conference
    do_403 unless @this_conference.is_public || @this_conference.host?(current_user)

    @workshops = Workshop.where(:conference_id => @conference.id)

    if @this_conference.workshop_schedule_published
      @event_dlg = true
      get_scheule_data(false)
    end

    if logged_in?
      if current_user.administrator?
        @links ||= []
        @links = [:edit]
      end
      
      if @this_conference.host? current_user
        @links ||= []
        @links = [:administrate]
      end
    end
  end

  def register
    set_conference

    @register_template = nil

    if logged_in?
      set_or_create_conference_registration

      @name = current_user.firstname
      # we should phase out last names
      @name += " #{current_user.lastname}" if current_user.lastname

      @name ||= current_user.username

      @is_host = @this_conference.host? current_user
    else
      @register_template = :confirm_email
    end

    steps = nil
    return do_404 unless registration_steps.present?
    
    @register_template = :administration if params[:admin_step].present?

    @errors = {}
    @warnings = []
    form_step = params[:button] ? params[:button].to_sym : nil

    # process any data that was passed to us
    if form_step
      if form_step.to_s =~ /^prev_(.+)$/
        steps = registration_steps
        @register_template = steps[steps.find_index($1.to_sym) - 1]
      elsif form_step == :paypal_confirm
        if @registration.present? && @registration.payment_confirmation_token == params[:confirmation_token]
          @amount = PayPal!.details(params[:token]).amount.total
          @registration.payment_info = {:payer_id => params[:PayerID], :token => params[:token], :amount => @amount}.to_yaml

          @amount = (@amount * 100).to_i.to_s.gsub(/^(.*)(\d\d)$/, '\1.\2')

          @registration.save!
        end

        @page_title = 'articles.conference_registration.headings.Payment'
        @register_template = :paypal_confirm
      elsif form_step == :paypal_confirmed
        info = YAML.load(@registration.payment_info)
        @amount = nil
        status = nil
        if ENV['RAILS_ENV'] == 'test'
          status = info[:status]
          @amount = info[:amount]
        else
          paypal = PayPal!.checkout!(info[:token], info[:payer_id], PayPalRequest(info[:amount]))
          status = paypal.payment_info.first.payment_status
          @amount = paypal.payment_info.first.amount.total
        end
        if status == 'Completed'
          @registration.registration_fees_paid ||= 0
          @registration.registration_fees_paid += @amount

          # don't complete the step unless fees have been paid
          if @registration.registration_fees_paid > 0
            @registration.steps_completed << :payment
            @registration.steps_completed.uniq!
          end

          @registration.save!
        else
          @errors[:payment] = :incomplete
          @register_template = :payment
        end
        @page_title = 'articles.conference_registration.headings.Payment'
      else

        case form_step
        when :confirm_email
          return do_confirm
        when :contact_info
          if params[:name].present? && params[:name].gsub(/[\s\W]/, '').present?
            current_user.firstname = params[:name].squish
            current_user.lastname = nil
          else
            @errors[:name] = :empty
          end

          if params[:location].present? && params[:location].gsub(/[\s\W]/, '').present? && (l = Geocoder.search(params[:location], language: 'en')).present?
            corrected = view_context.location(l.first, @this_conference.locale)

            if corrected.present?
              @registration.city = corrected
              if params[:location].gsub(/[\s,]/, '').downcase != @registration.city.gsub(/[\s,]/, '').downcase
                @warnings << view_context._('warnings.messages.location_corrected', vars: {original: params[:location], corrected: corrected})
              end
            else
              @errors[:location] = :unknown
            end
          else
            @errors[:location] = :empty
          end

          if params[:languages].present?
            current_user.languages = params[:languages].keys
          else
            @errors[:languages] = :empty
          end

          current_user.save! unless @errors.present?
        when :hosting
          @registration.can_provide_housing = params[:can_provide_housing].present?
          if params[:not_attending]
            @registration.is_attending = 'n'

            if current_user.is_subscribed.nil?
              current_user.is_subscribed = false
              current_user.save!
            end
          else
            @registration.is_attending = 'y'
          end

          @registration.housing_data = {
            address: params[:address],
            phone: params[:phone],
            space: {
              bed_space: params[:bed_space],
              floor_space: params[:floor_space],
              tent_space: params[:tent_space],
            },
            considerations: (params[:considerations] || {}).keys,
            availability: [ params[:first_day], params[:last_day] ],
            notes: params[:notes]
          }
        when :questions
          # create the companion's user account and send a registration link unless they have already registered
          generate_confirmation(User.create(email: params[:companion]), register_path(@this_conference.slug)) if params[:companion].present? && User.find_by_email(params[:companion]).nil?
          
          @registration.housing = params[:housing]
          @registration.arrival = params[:arrival]
          @registration.departure = params[:departure]
          @registration.housing_data = {
            companions: [ params[:companion] ]
          }
          @registration.bike = params[:bike]
          @registration.food = params[:food]
          @registration.allergies = params[:allergies]
          @registration.other = params[:other]
        when :payment
          amount = params[:amount].to_f

          if amount > 0
            @registration.payment_confirmation_token = ENV['RAILS_ENV'] == 'test' ? 'token' : Digest::SHA256.hexdigest(rand(Time.now.to_f * 1000000).to_i.to_s)
            @registration.save
            
            host = "#{request.protocol}#{request.host_with_port}"
            response = PayPal!.setup(
              PayPalRequest(amount),
              register_paypal_confirm_url(@this_conference.slug, :paypal_confirm, @registration.payment_confirmation_token),
              register_paypal_confirm_url(@this_conference.slug, :paypal_cancel, @registration.payment_confirmation_token),
              noshipping: true,
              version: 204
            )
            if ENV['RAILS_ENV'] != 'test'
              redirect_to response.redirect_uri
            end
            return
          end
        end

        if @errors.present?
          @register_template = form_step
        else
          unless @registration.nil?
            steps = registration_steps
            step_index = steps.find_index(form_step)
            @register_template = steps[step_index + 1] if step_index.present?

            # have we reached a new level?
            unless @registration.steps_completed.include? form_step.to_s
              # this step is only completed if a payment has been made
              if form_step != :payment || (@registration.registration_fees_paid || 0) > 0
                @registration.steps_completed ||= []
                @registration.steps_completed << form_step
                @registration.steps_completed.uniq!
              end
            end

            @registration.save!
          end
        end
      end
    end

    steps ||= registration_steps

    # make sure we're on a valid step
    @register_template ||= (params[:step] || current_step).to_sym

    if logged_in? && @register_template != :paypal_confirm
      # if we're logged in
      if !steps.include?(@register_template)
        # and we are not viewing a valid step
        return redirect_to register_path(@this_conference.slug)
      elsif @register_template != current_step && !registration_complete? && !@registration.steps_completed.include?(@register_template.to_s)
        # or the step hasn't been reached, registration is not yet complete, and we're not viewing the latest incomplete step
        return redirect_to register_path(@this_conference.slug)
      end
      # then we'll redirect to the current registration step
    end

    # prepare the form
    case @register_template
    when :questions
      # see if someone else has asked to be your companion
      if @registration.housing_data.blank?
        ConferenceRegistration.where(
          conference_id: @this_conference.id, can_provide_housing: [nil, false]
          ).where.not(housing_data: nil).each do | r |
          @registration.housing_data = {
              companions: [ r.user.email ]
            } if r.housing_data['companions'].present? && r.housing_data['companions'].include?(current_user.email)
        end
        
        @registration.housing_data ||= { }
      end
      @page_title = 'articles.conference_registration.headings.Registration_Info'
    when :payment
      @page_title = 'articles.conference_registration.headings.Payment'
    when :workshops
      @page_title = 'articles.conference_registration.headings.Workshops'
      
      # initialize our arrays
      @my_workshops = Array.new
      @requested_workshops = Array.new
      @workshops_in_need = Array.new
      @workshops = Array.new

      # put wach workshop into the correct array
      Workshop.where(conference_id: @this_conference.id).each do | workshop |
        if workshop.active_facilitator?(current_user)
          @my_workshops << workshop
        elsif workshop.requested_collaborator?(current_user)
          @requested_workshops << workshop
        elsif workshop.needs_facilitators
          @workshops_in_need << workshop
        else
          @workshops << workshop
        end
      end

      # sort the arrays by name
      @my_workshops.sort! { |a, b| a.title.downcase <=> b.title.downcase }
      @requested_workshops.sort! { |a, b| a.title.downcase <=> b.title.downcase }
      @workshops_in_need.sort! { |a, b| a.title.downcase <=> b.title.downcase }
      @workshops.sort! { |a, b| a.title.downcase <=> b.title.downcase }
    when :contact_info
      @page_title = 'articles.conference_registration.headings.Contact_Info'
    when :hosting
      @page_title = 'articles.conference_registration.headings.Hosting'
      @hosting_data = @registration.housing_data || {}
      @hosting_data['space'] ||= Hash.new
      @hosting_data['availability'] ||= Array.new
      @hosting_data['considerations'] ||= Array.new
    when :policy
      @page_title = 'articles.conference_registration.headings.Policy_Agreement'
    when :confirm_email
      @page_title = "articles.conference_registration.headings.#{@this_conference.registration_status == :open ? '': 'Pre_'}Registration_Details"
      @main_title = "articles.conference_registration.headings.#{@this_conference.registration_status == :open ? '': 'Pre_'}Register"
      @main_title_vars = { vars: { title: @this_conference.title } }
    end

  end

  # helper_method :registration_steps
  # helper_method :current_registration_steps
  helper_method :registration_complete?

  def registration_steps(conference = nil)
    conference ||= @this_conference || @conference
    status = conference.registration_status

    steps = status == :pre || status == :open ? [
        :policy,
        :contact_info,
        :questions,
        :hosting,
        :payment,
        :workshops
      ] : []
    
    steps -= [:questions] unless status == :open
    steps -= [:payment] unless status == :open && conference.paypal_email_address.present? && conference.paypal_username.present? && conference.paypal_password.present? && conference.paypal_signature.present?
    if @registration.present?
      if view_context.same_city?(@registration.city, view_context.location(conference.location, conference.locale))
        steps -= [:questions]
        
        # if this is a housing provider that is not attending the conference, remove these steps
        if @registration.is_attending == 'n'
          steps -= [:payment, :workshops]
        end
      else
        steps -= [:hosting]
      end
    else
      steps -= [:hosting, :questions]
    end

    steps += [:administration] if conference.host?(current_user)

    return steps
  end

  def required_steps(conference = nil)
    # return the intersection of current steps and required steps
    registration_steps(conference || @this_conference || @conference) & # current steps
      [:policy, :contact_info, :hosting, :questions] # all required steps
  end

  def registration_complete?(registration = @registration)
    completed_steps = registration.steps_completed || []
    required_steps(registration.conference).each do | step |
      return true if step == :workshops
      return false unless completed_steps.include?(step.to_s)
    end
    return true
  end

  rescue_from ActiveRecord::PremissionDenied do |exception|
    if !@this_conference.can_register?
      do_404
    elsif logged_in?
      redirect_to 'conferences/register'
    else
      @register_template = :confirm_email
      @page_title = "articles.conference_registration.headings.#{@this_conference.registration_status == :open ? '': 'Pre_'}Registration_Details"
      @main_title = "articles.conference_registration.headings.#{@this_conference.registration_status == :open ? '': 'Pre_'}Register"
      @main_title_vars = { vars: { title: @this_conference.title } }
      render 'conferences/register'
    end
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    do_404
  end

  private

    def PayPal!
      Paypal::Express::Request.new(
        username:  @this_conference.paypal_username,
        password:  @this_conference.paypal_password,
        signature: @this_conference.paypal_signature
      )
    end

    def PayPalRequest(amount)
      Paypal::Payment::Request.new(
        :currency_code => 'USD',   # if nil, PayPal use USD as default
        :description   => 'Conference Registration',    # item description
        :quantity      => 1,      # item quantity
        :amount        => amount.to_f,   # item value
        :custom_fields => {
          CARTBORDERCOLOR: "00ADEF",
          LOGOIMG: "https://en.bikebike.org/assets/bblogo-paypal.png"
        }
      )
    end
end
