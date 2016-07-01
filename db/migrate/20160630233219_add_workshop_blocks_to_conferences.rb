class AddWorkshopBlocksToConferences < ActiveRecord::Migration
  def change
    add_column :conferences, :workshop_blocks, :json
  end
end
