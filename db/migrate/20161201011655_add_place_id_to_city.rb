require 'geocoder/calculations'

class AddPlaceIdToCity < ActiveRecord::Migration
  def change
    add_column :cities, :place_id, :string
  end
end
