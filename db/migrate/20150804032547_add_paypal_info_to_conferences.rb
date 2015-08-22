class AddPaypalInfoToConferences < ActiveRecord::Migration
  def change
    add_column :conferences, :paypal_username, :string
    add_column :conferences, :paypal_password, :string
    add_column :conferences, :paypal_signature, :string
  end
end
