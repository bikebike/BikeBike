class AddSpaceToEventLocations < ActiveRecord::Migration
  def change
    add_column :event_locations, :space, :string
  end
end
