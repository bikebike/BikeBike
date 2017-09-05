require 'geocoder/calculations'
require 'rest_client'
require 'registration_controller_helper'

class ConferencesController < ApplicationController
  include RegistrationControllerHelper

  def list
    @page_title = 'articles.conferences.headings.Conference_List'
    @conference_list = { future: [], passed: [] }
    Conference.all.order("start_date DESC").each do |conference|
      if conference.is_public || conference.host?(current_user)
        @conference_list[conference.over? ? :passed : :future] << conference
      end
    end
    @conference_list[:future].reverse!
  end

  def view
    set_conference
    do_403 unless @this_conference.is_public || @this_conference.host?(current_user)

    @workshops = Workshop.where(:conference_id => @this_conference.id)

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
        @links = [:administrate, :register]
      end
    end
  end

  def register
    set_conference
    do_403 unless @this_conference.is_public || @this_conference.host?(current_user)
    do_403 unless @this_conference.registration_open || @this_conference.registered?(current_user)

    if logged_in?
      if request.post?
        # update this step
        result = if params[:step].to_sym == :confirm_payment
                   request_data = paypal_payment_request_data(@this_conference, current_user)
                   paypal_confirm_request = paypal_payment_request(request_data[:amount], request_data[:currency])
                   update_registration_step!(:payment_form, @this_conference, current_user, params) do
                     paypal_payment_complete(paypal_confirm_request, @this_conference, current_user, params)
                   end
                 else
                   update_registration_step(params[:step].to_sym, @this_conference, current_user, params)
                 end

        # set the message if we got one
        @update_status = result[:status]
        @update_message = result[:message]

        # pass any data on to the view
        data_to_instance_variables(result[:data])

        handle_exception(result[:exception]) if result[:exception].present?

        if @update_status == :paypal_redirect
          pp_response = @request.setup(
            paypal_payment_request(@amount, @currency),
            register_url(@this_conference.slug, @confirm_args),
            register_url(@this_conference.slug, @cancel_args),
            noshipping: true,
            version: 204
          )
          return redirect_to pp_response.redirect_uri
        end
      end
begin
      # get the current step
      @step = current_registration_step(@this_conference, current_user)

      if @update_status.nil? && flash[:status_message].present?
        @update_status = flash[:status_message][:status]
        @update_message = flash[:status_message][:message]
      end

      if @step == :payment_form && (params[:token].present? || @test_token.present?)
        result = paypal_payment_confirm(@this_conference, current_user, params)
        data_to_instance_variables(result)
        @confirm_payment = true
      end

      # set up the next step
      result = registration_step(@step, @this_conference, current_user)
      # pass any data on to the view
      data_to_instance_variables(result)
rescue Exception => e
  puts e
  puts e.backtrace.join("\n")
  raise e
end
    end

    if request.xhr?
      render json: [{
          globalSelector: '#step-content',
          html: view_context.step_message + render_to_string(partial: "registration_steps/#{@step}"),
          scrollTo: '#action-message .message, #step-content',
          focus: 'input:not([type="hidden"]), textarea, button.selected'
        }]
    end
  end

  def survey
    set_conference
    ensure_registration_is_complete!
    return do_403 unless @this_conference.post_conference_survey_available? || @registration.survey_taken
  end

  def save_survey
    set_conference
    ensure_registration_is_complete!
    return do_403 unless @this_conference.post_conference_survey_available?(@registration) && !@registration.survey_taken

    # compile the results
    results = {}
    @this_conference.post_conference_survey_questions.each do |name, question|
      case question[:type]
      when :multi_likert
        answer = {}
        question[:questions].each do |q|
          r = params["#{name}_#{q}"]
          answer[q] = r if r.present? && question[:options].include?(r.to_sym)
        end
        results[name] = answer
      else
        answer = params[name]
        if answer.present?
          unless question[:waive_option].present? && answer.to_sym == question[:waive_option]
            results[name] = answer
          end
        end
      end
    end

    # create the survey
    Survey.create(
        name: @this_conference.post_conference_survey_name,
        version: @this_conference.post_conference_survey_version,
        results: results
      )

    # mark this user as having taken the survey
    @registration.survey_taken = true
    @registration.save!

    redirect_to conference_survey_path
  end

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
      if view_context.potential_provider(@registration)
        steps -= [:questions]
        
        # if this is a housing provider that is not attending the conference, remove these steps
        steps -= [:payment, :workshops] if @registration.is_attending == 'n'
      else
        steps -= [:hosting]
      end
    else
      steps -= [:hosting, :questions]
    end

    return steps
  end

  def required_steps(conference = nil)
    # return the intersection of current steps and required steps
    registration_steps(conference || @this_conference || @conference) & # current steps
      [:policy, :contact_info, :hosting, :questions] # all required steps
  end

  def registration_complete?(registration = @registration)
    completed_steps = registration.steps_completed || []
    required_steps(registration.conference).each do |step|
      return true if step == :workshops
      return false unless completed_steps.include?(step.to_s)
    end
    return true
  end

  rescue_from ActiveRecord::PremissionDenied do |exception|
    if !@this_conference.can_register?
      do_403
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

  def send_registration_confirmation_email(registration)
    send_mail(:registration_confirmation, registration.id)
  end

  def paypal_payment_request(amount, currency)
    Paypal::Payment::Request.new(
      currency_code: currency.to_s,
      description:   'Bike!Bike! Registration',
      quantity:      1,
      amount:        amount.to_f,
      custom_fields: {
        CARTBORDERCOLOR: "00ADEF",
        LOGOIMG: "https://en.bikebike.org/assets/bblogo-paypal.png"
      }
    )
  end

  def data_to_instance_variables(data)
    return unless data
    data.each do |key, value|
      instance_variable_set("@#{key}", value) unless instance_variable_defined?("@#{key}")
    end
  end
end
