class AddStepsCompletedToConferenceRegistrations < ActiveRecord::Migration
  def change
    add_column :conference_registrations, :steps_completed, :json
  end
end
