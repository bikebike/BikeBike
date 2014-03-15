class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :title
      t.string :slug
      t.integer :event_type_id
      t.conference_id :conference
      t.text :info
      t.location_id :location
      t.datetime :start_time
      t.datetime :end_time

      t.timestamps
    end
  end
end
