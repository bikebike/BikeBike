class AddOrderToWorkshopStreams < ActiveRecord::Migration
  def change
    add_column :workshop_streams, :order, :integer
  end
end
