require 'geocoder/calculations'

class RenameCityMatches < ActiveRecord::Migration
  def change
    rename_table :city_matches, :city_cache
    
    Conference.all.each do |c|
      conference_location = c.location

      if conference_location.present?
        location = Geocoder.search("#{conference_location.city}, #{conference_location.territory}, #{conference_location.country}", language: 'en').first

        component_alises = {
          'locality' => :city,
          'administrative_area_level_1' => :territory,
          'country' => :country
        }
        city_data = {
          locale: :en,
          latitude: location.data['geometry']['location']['lat'],
          longitude: location.data['geometry']['location']['lng']
        }
        location.data['address_components'].each do | component |
          property = component_alises[component['types'].first]
          city_data[property] = component['short_name'] if property.present?
        end

        city = City.where(city: city_data[:city], territory: city_data[:territory], country: city_data[:country]).first
        
        unless city.present?
          city = City.new(city_data)
          city.save!
        end
        
        c.update_attribute :city_id, city.id
      end
    end
  end
end
