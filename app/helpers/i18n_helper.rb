
module I18nHelper
  def url_for_locale(locale, url = nil)
    return url unless locale.present?

    unless url.present?
      new_params = params.merge({action: (params[:_original_action] || params[:action])})
      new_params.delete(:_original_action)

      if Rails.env.development? || Rails.env.test?
        return url_for(new_params.merge({lang: locale.to_s}))
      end
    
      subdomain = Rails.env.preview? ? "preview-#{locale.to_s}" : locale.to_s
      return url_for(new_params.merge(host: "#{subdomain}.bikebike.org"))
    end

    return url if Rails.env.development? || Rails.env.test?
    return "https://preview-#{locale.to_s}.bikebike.org#{url}" if Rails.env.preview?
    "https://#{locale.to_s}.bikebike.org#{url}"
  end

  def date(date, format = :long)
    I18n.l(date.is_a?(String) ? Date.parse(date) : date, :format => format)
  end

  def time(time, format = :short)
    if time.is_a?(String)
      time = Date.parse(time)
    elsif time.is_a?(Float) || time.is_a?(Integer)
      time = DateTime.now.midnight + time.hours
    end
        
    I18n.l(time, format: format)
  end

  def date_span(date1, date2)
    key = 'same_month'
    if date1.year != date2.year
      key = 'different_year'
    elsif date1.month != date2.month
      key = 'same_year'
    end
    d1 = I18n.l(date1.to_date, format: "span_#{key}_date_1".to_sym)
    d2 = I18n.l(date2.to_date, format: "span_#{key}_date_2".to_sym)
    _('date.date_span', vars: {:date_1 => d1, :date_2 => d2})
  end

  def time_length(length)
    hours = length.to_i
    minutes = ((length - hours) * 60).to_i
    hours = hours > 0 ? (I18n.t 'datetime.distance_in_words.x_hours', count: hours) : nil
    minutes = minutes > 0 ? (I18n.t 'datetime.distance_in_words.x_minutes', count: minutes) : nil
    return hours.present? ? (minutes.present? ? (I18n.t 'datetime.distance_in_words.x_and_y', x: hours, y: minutes) : hours) : minutes
  end

  def hour_span(time1, time2)
    (time2 - time1) / 3600
  end

  def hours(time1, time2)
    time_length hour_span(time1, time2)
  end

  def money(amount)
    return _!('$0.00') if amount == 0
    _!((amount * 100).to_i.to_s.gsub(/^(.*)(\d\d)$/, '$\1.\2'))
  end

  def percent(p)
    return _!('0.00%') if p == 0
    _!((p * 10000).to_i.to_s.gsub(/^(.*)(\d\d)$/, '\1.\2%'))
  end
end
