class AddCoverToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :cover, :string
  end
end
