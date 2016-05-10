class AddStatusToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :status, :string
  end
end
