class AddCoverAttributionUserIdToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :cover_attribution_user_id, :integer
  end
end
