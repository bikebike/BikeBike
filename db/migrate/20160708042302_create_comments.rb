class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.string :model_type
      t.integer :model_id
      t.text :comment

      t.timestamps null: false
    end
  end
end
