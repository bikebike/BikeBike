class AddCoverAttributionSrcToOrganizations < ActiveRecord::Migration
  def change
    add_column :organizations, :cover_attribution_src, :string
  end
end
