module RegistrationHelper
  def current_registration_steps(registration = @registration)
    return nil unless registration.present?

    steps = registration_steps(registration.conference)
    current_steps = []
    disable_steps = false
    completed_steps = registration.steps_completed || []
    registration_complete = registration_complete?(registration)

    if registration.city_id == registration.conference.city_id
      steps -= [:questions]
    else
      steps -= [:hosting]
    end
    
    steps.each do | step |
      # disable the step if we've already found an incomplete step
      enabled = !disable_steps || registration_complete
      # record whether or not we've found an incomplete step
      disable_steps ||= !completed_steps.include?(step.to_s)

      current_steps << {
        name:    step,
        enabled: enabled
      }
    end
    return current_steps
  end

  def current_step(registration = @registration)
    completed_steps = registration.steps_completed || []
    (registration_steps(registration.conference) || []).each do | step |
      return step unless completed_steps.include?(step.to_s)
    end
    return registration_steps(registration.conference).last
  end
end
