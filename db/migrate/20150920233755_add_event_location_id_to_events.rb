class AddEventLocationIdToEvents < ActiveRecord::Migration
  def change
    add_column :events, :event_location_id, :integer
  end
end
