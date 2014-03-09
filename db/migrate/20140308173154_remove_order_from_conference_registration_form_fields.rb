class RemoveOrderFromConferenceRegistrationFormFields < ActiveRecord::Migration
  def change
    remove_column :conference_registration_form_fields, :order, :integer
  end
end
