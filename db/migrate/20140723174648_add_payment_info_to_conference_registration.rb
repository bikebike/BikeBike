class AddPaymentInfoToConferenceRegistration < ActiveRecord::Migration
  def change
    add_column :conference_registrations, :payment_info, :string
  end
end
