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
end
