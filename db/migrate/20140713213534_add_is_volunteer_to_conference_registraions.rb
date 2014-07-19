class AddIsVolunteerToConferenceRegistraions < ActiveRecord::Migration
  def change
    add_column :conference_registrations, :is_volunteer, :boolean
  end
end
