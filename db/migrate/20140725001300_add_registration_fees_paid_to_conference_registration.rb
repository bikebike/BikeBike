class AddRegistrationFeesPaidToConferenceRegistration < ActiveRecord::Migration
  def change
    add_column :conference_registrations, :registration_fees_paid, :integer
  end
end
