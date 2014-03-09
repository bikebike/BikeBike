class CreateWorkshopStreams < ActiveRecord::Migration
  def change
    create_table :workshop_streams do |t|
      t.string :name
      t.string :slug
      t.string :info

      t.timestamps
    end
  end
end
