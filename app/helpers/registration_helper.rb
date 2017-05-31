module RegistrationHelper
  def registration_steps(conference = @conference)
    {
      pre: [:policy, :contact_info, :workshops],
      open: [:policy, :contact_info, :questions, :hosting, :payment, :workshops]
    }[@this_conference.registration_status]
  end

  def registration_status(registration)
    return :unregistered if registration.nil?
    return registration.status
  end

  def current_registration_steps(registration = @registration)
    return nil unless registration.present?

    steps = registration_steps(registration.conference)
    current_steps = []
    disable_steps = false
    completed_steps = registration.steps_completed || []

    if potential_provider(registration)
      steps -= [:questions]
    else
      steps -= [:hosting]
    end

    steps -= [:payment] unless registration.conference.paypal_email_address.present? && registration.conference.paypal_username.present? && registration.conference.paypal_password.present? && registration.conference.paypal_signature.present?
    steps -= [:payment, :workshops] if registration.is_attending == 'n'
    
    steps.each do |step|
      # disable the step if we've already found an incomplete step
      # enabled = !disable_steps# || registration_complete
      # record whether or not we've found an incomplete step

      current_steps << {
        name:    step,
        enabled: !disable_steps
      }
      disable_steps ||= !completed_steps.include?(step.to_s)# && ![:payment, :workshops].include?(step)
    end

    return current_steps
  end

  def current_step(registration = @registration)
    completed_steps = registration.steps_completed || []
    last_step = nil
    steps = current_registration_steps(registration) || []
    steps.each do | step |
      # return the last enabled step if this one is disabled
      return last_step unless step[:enabled]

      # save the last step
      last_step = step[:name]

      # return this step if it hasn't been completed yet
      return last_step unless completed_steps.include?(last_step.to_s)
    end

    # if all else fails, return the first step
    return steps.last[:name]
  end

  def registration_step_header(step = @step, vars = nil)
    if step.is_a?(Hash)
      vars = step
      step = @step
    end
    vars ||= {}
    row do
      columns(medium: 12) do
        registration_step_header_title(step, vars[:header])
      end.html_safe +
      columns(medium: 12) do
        registration_step_header_description(step, vars[:description])
      end.html_safe
    end.html_safe
  end

  def registration_step_header_title(step = @step, vars = nil)
    if step.is_a?(Hash)
      vars = step
      step = @step
    end
    content_tag(:h2, (_"articles.conference_registration.headings.#{@step}", :t, 2, vars: vars || {})).html_safe
  end

  def registration_step_header_description(step = @step, vars = nil)
    if step.is_a?(Hash)
      vars = step
      step = @step
    end
    content_tag(:p, (_"articles.conference_registration.paragraphs.#{@step}", :p, 2, vars: vars || {})).html_safe
  end

  def save_registration_step(conference = @this_conference, step = @step, &block)
    buttons = [:back]
    case step.to_sym
    when :policy
      buttons = [:agree]
    when :name, :languages, :org_location, :org_create_name, :org_create_address, :org_create_email, :org_create_mailing_address, :housing_companion_email, :housing_companion_invite, :housing_allergies, :housing_other
      buttons = [:next, :back]
    when :org_location_confirm
      buttons = [:yes, :back]
    when :review
      buttons = nil
    end

    content = block.present? ? capture(&block) : ''
    actions = ''
    if buttons.present?
      buttons.each do |button_name|
        actions += (button button_name, value: button_name)
      end
    end

    form_tag(register_path(conference.slug), class: 'js-xhr') do
      (@update_message.present? && @update_status.present? ? columns(medium: 12, class: @update_status, id: 'action-message') do
        content_tag(:div, (_"articles.conference_registration.#{@update_status}.#{@update_message}", :s), class: :message).html_safe
      end : '').html_safe +
      content.html_safe +
      (hidden_field_tag :step, step).html_safe +
      columns(medium: 12, class: [:actions, :center]) do
        content_tag(:div, actions.html_safe, class: :buttons).html_safe
      end.html_safe
    end.html_safe
  end
end
