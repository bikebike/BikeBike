class AddRegistrationStatusToConferences < ActiveRecord::Migration
  def change
    add_column :conferences, :registration_status, :string
    Conference.find_each do |conference|
    	conference.registration_status = conference.registration_open ? :open : :closed
    	conference.save!
    end
  end
end
