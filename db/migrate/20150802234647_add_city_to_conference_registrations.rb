class AddCityToConferenceRegistrations < ActiveRecord::Migration
  def change
    add_column :conference_registrations, :city, :string
    add_column :conference_registrations, :arrival, :datetime
    add_column :conference_registrations, :departure, :datetime
    add_column :conference_registrations, :housing, :string
    add_column :conference_registrations, :bike, :string
    add_column :conference_registrations, :other, :text
  end
end
