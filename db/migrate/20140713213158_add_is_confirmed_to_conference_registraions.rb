class AddIsConfirmedToConferenceRegistraions < ActiveRecord::Migration
  def change
    add_column :conference_registrations, :is_confirmed, :boolean
  end
end
