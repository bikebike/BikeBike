require 'geocoder'
require 'geocoder/railtie'
require 'geocoder/calculations'

Geocoder::Railtie.insert

class City < ActiveRecord::Base
  geocoded_by :address
  translates :city

  reverse_geocoded_by :latitude, :longitude, :address => :full_address
  after_validation :geocode, if: ->(obj){ obj.country_changed? or obj.territory_changed? or obj.city_changed? or obj.latitude.blank? or obj.longitude.blank?  }

  def address
    ([city!, territory, country] - [nil, '']).join(', ')
  end

  def get_translation(locale)
    location = Geocoder.search(address, language: locale.to_s).first

    # if the service lets us down, return nil
    return nil unless location.present?

    searched_component = false
    location.data['address_components'].each do | component |
      # city is usually labeled a 'locality' but sometimes this is missing and only 'colloquial_area' is present
      if component['types'].first == 'locality'
        return component['short_name']
      end

      if component['types'] == location.data['types']
        searched_component = component['short_name']
      end
    end

    # return the type we searched for but it's still possible that it will be false
    searched_component
  end

  # this method will get called automatically if a translation is asked for but not found
  def translate_city(locale)
    translation = get_translation(locale)
    
    # if we found it, set it
    if translation.present?
      set_column_for_locale(:city, locale, translation)
      save!
    end
    
    return translation
  end

  def self.search(str)
    cache = CityCache.search(str)

    # return the city if this search is in our cache
    return cache.city if cache.present?

    # look up the city in the geocoder
    location = Geocoder.search(str, language: 'en').first

    # return nil to indicate that the service is down
    return nil unless location.present?
    # see if the city is already present in our database
    city = City.find_by_place_id(location.data['place_id'])

    # return the city if we found it in the db already
    if city.present?
      CityCache.cache(str, city.id)
      return city
    end

    # otherwise build a new city
    component_alises = {
      'locality' => :city,
      'administrative_area_level_1' => :territory,
      'country' => :country
    }
    city_data = {
      locale: :en,
      latitude: location.data['geometry']['location']['lat'],
      longitude: location.data['geometry']['location']['lng'],
      place_id: location.data['place_id']
    }

    # these things are definitely not cities, make sure we don't think they're one
    not_a_city = [
        'administrative_area_level_1',
        'country',
        'street_address',
        'street_number',
        'postal_code',
        'postal_code_prefix',
        'route',
        'intersection',
        'premise',
        'subpremise',
        'natural_feature',
        'airport',
        'park',
        'point_of_interest',
        'bus_station',
        'train_station',
        'transit_station',
        'room',
        'post_box',
        'parking',
        'establishment',
        'floor'
      ]

    searched_component = nil
    location.data['address_components'].each do | component |
      property = component_alises[component['types'].first]
      city_data[property] = component['short_name'] if property.present?

      # ideally we will find the component that is labeled a locality but
      # if that fails we will select what was searched for, hopefully they searched for a city
      # and not an address or country
      # some places are not labeled 'locality', search for 'Halifax NS' for example and you will
      # get 'administrative_area_level_2' since Halifax is a municipality
      if component['types'] == location.data['types'] && !not_a_city.include?(component['types'].first)
        searched_component = component['short_name']
      end
    end

    # fall back to the searched component 
    city_data[:city] ||= searched_component

    # we need to have the city and country at least
    return false unless city_data[:city].present? && city_data[:country].present?

    # save the new city
    city = City.new(city_data)
    city.save!

    # save this to our cache
    CityCache.cache(str, city.id)

    # and return it
    return city
  end
end
