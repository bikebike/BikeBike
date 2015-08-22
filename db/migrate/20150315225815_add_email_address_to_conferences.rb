class AddEmailAddressToConferences < ActiveRecord::Migration
  def change
    add_column :conferences, :email_address, :string
  end
end
