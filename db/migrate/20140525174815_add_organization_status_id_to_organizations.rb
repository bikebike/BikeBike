class AddOrganizationStatusIdToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :organization_status_id, :integer
  end
end
