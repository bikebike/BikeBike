class RemoveLocationIdFromOrganizations < ActiveRecord::Migration
  def change
    remove_column :organizations, :location_id, :integer
  end
end
