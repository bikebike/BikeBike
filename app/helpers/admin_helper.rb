module AdminHelper

  def administration_steps
    {
      info: [
          :administrators,
          :dates,
          :poster
        ],
      copy: [
          :description,
          :group_ride,
          :housing_info,
          :workshop_info,
          :payment_message,
          :schedule_info,
          :travel_info,
          :city_info,
          :what_to_bring,
          :volunteering_info,
          :additional_details
        ],
      payment: [
          :suggested_amounts,
          :paypal
        ],
      registration: [
          :registration_status,
          :stats,
          :registrations,
          :broadcast,
          :check_in
        ],
      housing: [
          :providers,
          :housing
        ],
      events: [
          :locations,
          :meals,
          :events,
          :workshops
        ],
      schedule: [
          :workshop_times,
          :schedule,
          :publish_schedule
        ]
    }
  end

  def administration_sub_steps
    {
      location_edit: :locations,
      event_edit: :events,
      broadcast_sent: :broadcast
    }
  end

  def get_administration_group(administration_step)
    admin_step = administration_step.to_sym
    admin_step = administration_sub_steps[admin_step] if administration_sub_steps[admin_step].present?
    administration_steps.each do |group, steps|
      steps.each do |step|
        return group if step == admin_step
      end
    end

    return nil
  end

  def broadcast_to(to, conference = nil)
    conference ||= @this_conference || @conference

    users = []
    
    case to.to_sym
    when :registered
      ConferenceRegistration.where(conference_id: conference.id).each do |r|
        users << r.user if r.registered? && r.user.present? && r.attending?
      end
    when :pre_registered
      ConferenceRegistration.where(conference_id: conference.id).each do |r|
        users << r.user if r.attending?
      end
    when :workshop_facilitators
      user_hash = {}
      Workshop.where(conference_id: conference.id).each do |w|
        w.active_facilitators.each do |u|
          user_hash[u.id] ||= u if u.present?
        end
      end
      users = user_hash.values
    when :unregistered
      ConferenceRegistration.where(conference_id: conference.id).each do |r|
        users << r.user if !r.registered? && r.attending?
      end
    when :housing_providers
      ConferenceRegistration.where(conference_id: conference.id, can_provide_housing: true).each do |r|
        users << r.user if r.user.present?
      end
    when :guests
      ConferenceRegistration.where(conference_id: conference.id, housing: 'house').each do |r|
        users << r.user if r.user.present? && r.attending?
      end
    when :all
      User.all.each do |u|
        users << u if u.present? && (u.is_subscribed.nil? || u.is_subscribed)
      end
    end
    
    return users
  end

  def get_housing_match(host, guest, space)
    housing_data = guest.housing_data || {}
    
    if housing_data['host'].present?
      if housing_data['host'] == host.id
        return space == housing_data['space'] ? :selected_space : :other_space
      end

      return :other_host
    end

    if space_matches?(space, guest.housing) && available_dates_match?(host, guest)
      return :good_match
    end

    return :bad_match
  end

  def get_workshop_match(workshop, day, division, time, block, location)
    if workshop.event_location_id.present? && workshop.present?
      if (Date.parse params[:day]).wday == workshop.block['day'] && block == workshop.block['block'].to_i
        return :selected_space
      end

      if location.present? && location.id == workshop.event_location_id
        return :other_space
      end

      return :other_host
    end

    if location.present?
      needs = JSON.parse(workshop.needs || '[]').map &:to_sym
      amenities = JSON.parse(location.amenities || '[]').map &:to_sym

      if (needs & amenities).length < needs.length
        return :bad_match
      end
    end

    @schedule ||= {}
    @schedule[day] ||= {}
    @schedule[day][division] ||= []
    @schedule[day][division][:times] ||= {}
    @schedule[day][division][:times][time] ||= {}
    @schedule[day][division][:times][time][:item] ||= {}
    @schedule[day][division][:times][time][:item][:workshops] || {}

    @schedule[day][division][:times][time][:item][:workshops].each do |l, w|
      if w[:workshop].id != workshop.id
        f_a = w[:workshop].active_facilitators.map { | f | f.id }
        f_b = workshop.active_facilitators.map { | f | f.id }
        if (f_a & f_b).present?
          return :bad_match
        end
      end
    end

    return :good_match
  end

  def space_matches?(host_space, guest_space)
    return false unless host_space.present? && guest_space.present?

    if host_space.to_s == 'bed_space' || host_space.to_s == 'floor_space'
      return guest_space.to_s == 'house'
    end

    return host_space.to_s == 'tent_space' && guest_space.to_s == 'tent'
  end

  def available_dates_match?(host, guest)
    return false unless host.housing_data['availability'].present? && host.housing_data['availability'][1].present?
    return false unless guest.arrival.present? && guest.departure.present?
    if host.housing_data['availability'][0].to_date <= guest.arrival.to_date &&
      host.housing_data['availability'][1].to_date >= guest.departure.to_date
      return true
     end

     return false
  end

  def copy_form(section)
    return (columns(medium: 12) do
      (admin_update_form do
        (translate_textarea(section, @this_conference, label: "articles.conference_registration.headings.admin.edit.#{section}", help: "articles.conference_registration.paragraphs.admin.edit.#{section}").html_safe +
        content_tag(:div, class: [:actions, :right]) do
          (button :save, value: :save).html_safe
        end).html_safe
      end).html_safe
    end).html_safe
  end

  def admin_help_pages
    return {
      housing: :housing
    }
  end
end
