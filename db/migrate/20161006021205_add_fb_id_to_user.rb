class AddFbIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :fb_id, :bigint
  end
end
