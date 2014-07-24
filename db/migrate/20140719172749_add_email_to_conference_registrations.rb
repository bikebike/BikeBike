class AddEmailToConferenceRegistrations < ActiveRecord::Migration
  def change
    add_column :conference_registrations, :email, :string
  end
end
