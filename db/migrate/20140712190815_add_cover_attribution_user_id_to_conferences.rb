class AddCoverAttributionUserIdToConferences < ActiveRecord::Migration
  def change
    add_column :conferences, :cover_attribution_user_id, :integer
  end
end
