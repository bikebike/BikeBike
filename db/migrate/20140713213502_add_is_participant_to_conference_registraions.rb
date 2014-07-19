class AddIsParticipantToConferenceRegistraions < ActiveRecord::Migration
  def change
    add_column :conference_registrations, :is_participant, :boolean
  end
end
