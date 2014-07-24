class AddCompletedToConferenceRegistrations < ActiveRecord::Migration
  def change
    add_column :conference_registrations, :completed, :boolean
  end
end
