class AddBlockToWorkshops < ActiveRecord::Migration
  def change
    add_column :workshops, :block, :json
  end
end
