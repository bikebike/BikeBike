class AddCoverAttributionUserIdToConferences < ActiveRecord::Migration
  def change
    add_column :conferences, :id, :integer
  end
end
