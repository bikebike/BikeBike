class AddCoverAttributionUserIdToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :id, :integer
  end
end
