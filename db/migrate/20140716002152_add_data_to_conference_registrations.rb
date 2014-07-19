class AddDataToConferenceRegistrations < ActiveRecord::Migration
  def change
    add_column :conference_registrations, :data, :binary
  end
end
