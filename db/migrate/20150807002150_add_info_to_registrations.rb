class AddInfoToRegistrations < ActiveRecord::Migration
  def change
    add_column :conference_registrations, :allergies, :string
    add_column :conference_registrations, :languages, :string
    add_column :conference_registrations, :food, :string
  end
end
