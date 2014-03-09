class CreateWorkshopResources < ActiveRecord::Migration
  def change
    create_table :workshop_resources do |t|
      t.string :name
      t.string :slug
      t.string :info

      t.timestamps
    end
  end
end
