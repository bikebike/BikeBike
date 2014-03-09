class CreateConferenceRegistratonFormFields < ActiveRecord::Migration
  def change
    create_table :conference_registraton_form_fields do |t|
      t.integer :conference_id
      t.integer :registration_form_field_id
      t.integer :order

      t.timestamps
    end
  end
end
