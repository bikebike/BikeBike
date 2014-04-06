class CreateWorkshopRequestedResources < ActiveRecord::Migration
  def change
    create_table :workshop_requested_resources do |t|
      t.integer :workshop_id
      t.integer :workshop_resource_id
      t.string :status

      t.timestamps
    end
  end
end
