class CreateConferenceTypes < ActiveRecord::Migration
  def change
    create_table :conference_types do |t|
      t.string :title
      t.string :info

      t.timestamps
    end
  end
end
