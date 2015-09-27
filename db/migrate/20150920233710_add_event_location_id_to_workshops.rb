class AddEventLocationIdToWorkshops < ActiveRecord::Migration
  def change
    add_column :workshops, :event_location_id, :integer
  end
end
