class AddCoverAttributionNameToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :cover_attribution_name, :string
  end
end
