class AddHighestStepToConferenceRegistrations < ActiveRecord::Migration
  def change
    add_column :conference_registrations, :highest_step, :string
  end
end
