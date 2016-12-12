require 'geocoder/calculations'

class AddPlaceIdToCity < ActiveRecord::Migration
  def change
    add_column :cities, :place_id, :string

    City.all.each do |c|
      location = Geocoder.search(c.address, language: 'en').first
      c.place_id = location.data['place_id']
      c.save!
    end
  end
end
