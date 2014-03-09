class CreateConferenceRegistrations < ActiveRecord::Migration
  def change
    create_table :conference_registrations do |t|
      t.integer :conference_id
      t.integer :user_id
      t.string :is_attending

      t.timestamps
    end
  end
end
