class AddCoverAttributionIdToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :cover_attribution_id, :integer
  end
end
