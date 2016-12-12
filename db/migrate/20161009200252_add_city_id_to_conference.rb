class AddCityIdToConference < ActiveRecord::Migration
  def change
    add_column :conferences, :city_id, :integer
  end
end
