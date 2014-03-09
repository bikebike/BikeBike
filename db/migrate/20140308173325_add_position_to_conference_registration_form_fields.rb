class AddPositionToConferenceRegistrationFormFields < ActiveRecord::Migration
  def change
    add_column :conference_registration_form_fields, :position, :integer
  end
end
