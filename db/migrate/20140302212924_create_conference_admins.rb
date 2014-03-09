class CreateConferenceAdmins < ActiveRecord::Migration
  def change
    create_table :conference_admins do |t|
      t.integer :conference_id
      t.integer :user_id

      t.timestamps
    end
  end
end
