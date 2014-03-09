class CreateVersions < ActiveRecord::Migration
  def change
    create_table :versions do |t|
      t.string :item_type
      t.integer :item_id
      t.string :event
      t.string :whodunnit
      t.text :object
      t.datetime :created_at

      # t.timestamps
    end
  end
end
