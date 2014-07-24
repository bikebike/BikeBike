class AddIsCompleteToConferenceRegistrations < ActiveRecord::Migration
  def change
    add_column :conference_registrations, :complete, :boolean
  end
end
