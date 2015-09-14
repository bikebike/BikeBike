class CreateWorkshopInterests < ActiveRecord::Migration
  def change
    create_table :workshop_interests do |t|
      t.integer :workshop_id
      t.integer :user_id

      t.timestamps null: false
    end
  end
end
