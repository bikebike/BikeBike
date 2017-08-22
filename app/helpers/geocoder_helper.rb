module GeocoderHelper
  def lookup_ip
    if request.remote_ip == '127.0.0.1' || request.remote_ip == '::1'
      session['remote_ip'] || (session['remote_ip'] = open("http://checkip.dyndns.org").first.gsub(/^.*\s([\d\.]+).*$/s, '\1').gsub(/[^\.\d]/, ''))
    else
      request.remote_ip
    end
  end

  def get_remote_location
    Geocoder.search(session['remote_ip'] || (session['remote_ip'] = open("http://checkip.dyndns.org").first.gsub(/^.*\s([\d\.]+).*$/s, '\1').gsub(/[^\.\d]/, '')), language: 'en').first
  end

  def lookup_ip_location
    begin
      if is_test? && ApplicationController::get_location.present?
        Geocoder.search(ApplicationController::get_location, language: 'en').first
      elsif request.remote_ip == '127.0.0.1' || request.remote_ip == '::1'
        get_remote_location
      else
        request.location || get_remote_location
      end
    rescue
      nil
    end
  end

  def potential_provider(registration)
    return false unless registration.present? && registration.city.present? && registration.conference.present?
    conditions = registration.conference.provider_conditions ||
                 Conference.default_provider_conditions
    return city_distance_less_than(registration.conference.city, registration.city,
                                   conditions['distance']['number'], conditions['distance']['unit'])
  end

  def city_distance_less_than(city1, city2, max_distance, unit)
    return false if city1.nil? || city2.nil?
    return true if city1.id == city2.id
    return false if max_distance < 1
    return Geocoder::Calculations.distance_between(
      [city1.latitude, city1.longitude], [city2.latitude, city2.longitude],
      units: unit.to_sym) < max_distance
  end

  def location(location, locale = I18n.locale)
    return nil if location.blank?

    city = nil
    region = nil
    country = nil
    if location.is_a?(Location) || location.is_a?(City)
      country = location.country
      region = location.territory
      city = location.city
    elsif location.data.present? && location.data['address_components'].present?
      component_map = {
        'locality' => :city,
        'administrative_area_level_1' => :region,
        'country' => :country
      }
      location.data['address_components'].each do | component |
        types = component['types']
        country = component['short_name'] if types.include? 'country'
        region = component['short_name'] if types.include? 'administrative_area_level_1'
        city = component['long_name'] if types.include? 'locality'
      end
    else
      country = location.data['country_code']
      region = location.data['region_code']
      city = location.data['city']
    end

    # we need cities for our logic, don't let this continue if we don't have one
    return nil unless city.present?

    hash = Hash.new
    region_translation = region.present? && country.present? ? I18n.t("geography.subregions.#{country}.#{region}", locale: locale, resolve: false) : ''
    country_translation = country.present? ? _("geography.countries.#{country}", locale: locale) : ''
    hash[:city] = _!(city) if city.present?
    hash[:region] = region_translation if region_translation.present?
    hash[:country] = country_translation if country_translation.present?

    # return the formatted location or the first value if we only have one value
    return hash.length > 1 ? _("geography.formats.#{hash.keys.join('_')}", locale: locale, vars: hash) : hash.values.first
  end

  def location_link(location, text = nil)
    return '' unless location.present?
    address = if text.is_a?(Symbol)
                location.send(text)
              elsif text.is_a?(String)
                text
              elsif location.is_a?(Location)
                location.street
              else
                location.address
              end
    return '' unless address.present?
    content_tag(:a, (_!address), href: "http://www.google.com/maps/place/#{location.latitude},#{location.longitude}")
  end

  def same_city?(location1, location2)
    return false unless location1.present? && location2.present?

    location1 = location(location1) unless location1.is_a?(String)
    location2 = location(location2) unless location2.is_a?(String)

    location1.eql? location2
  end
end
