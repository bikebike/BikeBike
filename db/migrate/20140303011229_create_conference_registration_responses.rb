class CreateConferenceRegistrationResponses < ActiveRecord::Migration
  def change
    create_table :conference_registration_responses do |t|
      t.integer :conference_registration_id
      t.integer :registration_form_field_id
      t.text :data

      t.timestamps
    end
  end
end
