class RenameConferenceRegistratonFormFieldsToConferenceRegistrationFormFields < ActiveRecord::Migration
  def change
    rename_table :conference_registraton_form_fields, :conference_registration_form_fields
  end
end
