class AddCoverAttributionToConferences < ActiveRecord::Migration
  def change
    add_column :conferences, :cover_attribution_id, :integer
    add_column :conferences, :cover_attribution_name, :string
    add_column :conferences, :cover_attribution_src, :string
  end
end
