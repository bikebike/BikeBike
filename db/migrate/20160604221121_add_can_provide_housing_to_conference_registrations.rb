class AddCanProvideHousingToConferenceRegistrations < ActiveRecord::Migration
  def change
    add_column :conference_registrations, :can_provide_housing, :boolean
  end
end
