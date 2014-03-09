class CreateConferences < ActiveRecord::Migration
  def change
    create_table :conferences do |t|
      t.string :title
      t.string :slug
      t.datetime :start_date
      t.datetime :end_date
      t.text :info
      t.string :poster
      t.string :cover
      t.boolean :workshop_schedule_published
      t.boolean :registration_open
      t.boolean :meals_provided
      t.text :meal_info
      t.text :travel_info
      t.integer :conference_type_id

      t.timestamps
    end
  end
end
