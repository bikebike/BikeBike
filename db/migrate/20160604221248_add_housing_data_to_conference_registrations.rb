class AddHousingDataToConferenceRegistrations < ActiveRecord::Migration
  def change
    add_column :conference_registrations, :housing_data, :json
  end
end
