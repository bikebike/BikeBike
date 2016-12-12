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

    location.data['address_components'].each do | component |
      if component['types'].first == 'locality'
        return component['short_name']
      end
    end

    return nil
  end

  def translate_city(locale)
    translation = get_translation(locale)
    set_column_for_locale(:city, locale, translation)
    save!
    
    return translation
  end

  def self.search(str)
    cache = CityCache.search(str)

    # return the city if this search is in our cache
    return cache.city if cache.present?

    # look up the city in the geocoder
    location = Geocoder.search(str, language: 'en').first

    # see if the city is already present in our database
    city = City.find_by_place_id(location.data['place_id'])

    # return the city if we found it in the db already
    return city if city.present?

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
    location.data['address_components'].each do | component |
      property = component_alises[component['types'].first]
      city_data[property] = component['short_name'] if property.present?
    end

    # save the new city
    city = City.new(city_data)
    city.save!

    # and return it
    return city
  end
end
