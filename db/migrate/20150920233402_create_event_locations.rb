class CreateEventLocations < ActiveRecord::Migration
  def change
    create_table :event_locations do |t|
      t.string :title
      t.integer :conference_id
      t.float :latitude
      t.float :longitude
      t.string :address
      t.string :amenities

      t.timestamps null: false
    end
  end
end
