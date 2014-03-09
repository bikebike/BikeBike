class AddTextFieldsToConference < ActiveRecord::Migration
  def change
    add_column :conferences, :preregistration_info, :text
    add_column :conferences, :registration_info, :text
    add_column :conferences, :postregistration_info, :text
  end
end
