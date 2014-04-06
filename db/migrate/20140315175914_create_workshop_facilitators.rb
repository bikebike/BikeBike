class CreateWorkshopFacilitators < ActiveRecord::Migration
  def change
    create_table :workshop_facilitators do |t|
      t.integer :user_id
      t.integer :workshop_id
      t.string :role

      t.timestamps
    end
  end
end
