class CreatePrimaryKeyForLocationsOrganizations < ActiveRecord::Migration
  def change
    add_index :locations_organizations, [:organization_id, :location_id], :name => 'loc_org_index'
  end
end
