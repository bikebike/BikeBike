class AddPaypalEmailAddressToConferences < ActiveRecord::Migration
  def change
    add_column :conferences, :paypal_email_address, :string
  end
end
