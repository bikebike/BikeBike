class AddPhoneToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :phone, :string
  end
end
