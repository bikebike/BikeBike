module RegistrationHelper
  def current_registration_steps(registration = @registration)
    return nil unless registration.present?

    steps = registration_steps(registration.conference)
    current_steps = []
    disable_steps = false
    completed_steps = registration.steps_completed || []
    # registration_complete = registration_complete?(registration)

    if potential_provider(registration)
      steps -= [:questions]
    else
      steps -= [:hosting]
    end
    
    steps.each do | step |
      # disable the step if we've already found an incomplete step
      enabled = !disable_steps# || registration_complete
      # record whether or not we've found an incomplete step
      disable_steps ||= !completed_steps.include?(step.to_s) && ![:payment, :workshops].include?(step)

      current_steps << {
        name:    step,
        enabled: enabled
      }
    end
    return current_steps
  end

  def current_step(registration = @registration)
    completed_steps = registration.steps_completed || []
    last_step = nil
    (current_registration_steps(registration) || []).each do | step |
      # return the last enabled step if this one is disabled
      return last_step unless step[:enabled]

      # save the last step
      last_step = step[:name]

      # return this step if it hasn't been completed yet
      return last_step unless completed_steps.include?(last_step.to_s)
    end

    # if all else fails, return the first step
    return registration_steps(registration.conference).last
  end
end
