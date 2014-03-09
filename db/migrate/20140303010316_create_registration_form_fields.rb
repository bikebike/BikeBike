class CreateRegistrationFormFields < ActiveRecord::Migration
  def change
    create_table :registration_form_fields do |t|
      t.string :title
      t.text :help
      t.boolean :required
      t.string :field_type
      t.string :options
      t.boolean :is_retired

      t.timestamps
    end
  end
end
