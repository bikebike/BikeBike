class AddConfirmationTokenToConferenceRegistrations < ActiveRecord::Migration
  def change
    add_column :conference_registrations, :confirmation_token, :string
  end
end
