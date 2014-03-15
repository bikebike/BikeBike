class CreateEventTypes < ActiveRecord::Migration
  def change
    create_table :event_types do |t|
      t.string :slug
      t.text :info

      t.timestamps
    end
  end
end
