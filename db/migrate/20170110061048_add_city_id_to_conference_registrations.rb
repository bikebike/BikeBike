class AddCityIdToConferenceRegistrations < ActiveRecord::Migration
  def change
    add_column :conference_registrations, :city_id, :integer
  end
end
