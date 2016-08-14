class AddPaymentMessageToConference < ActiveRecord::Migration
  def change
    add_column :conferences, :payment_message, :text
  end
end
