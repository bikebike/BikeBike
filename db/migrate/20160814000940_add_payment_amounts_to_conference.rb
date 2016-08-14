class AddPaymentAmountsToConference < ActiveRecord::Migration
  def change
    add_column :conferences, :payment_amounts, :json
  end
end
