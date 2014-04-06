class CreateWorkshops < ActiveRecord::Migration
  def change
    create_table :workshops do |t|
      t.string :title
      t.string :slug
      t.text :info
      t.integer :conference_id
      t.integer :workshop_stream_id
      t.integer :workshop_presentation_style
      t.integer :min_facilitators
      t.integer :location_id
      t.datetime :start_time
      t.datetime :end_time

      t.timestamps
    end
  end
end
