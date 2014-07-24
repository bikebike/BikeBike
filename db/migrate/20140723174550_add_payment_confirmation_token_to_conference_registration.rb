class AddPaymentConfirmationTokenToConferenceRegistration < ActiveRecord::Migration
  def change
    add_column :conference_registrations, :payment_confirmation_token, :string
  end
end
