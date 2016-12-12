class AddCityIdToLocation < ActiveRecord::Migration
  def change
    add_column :locations, :city_id, :integer

    Location.all.each do |l|
      city = City.search(([l.city, l.territory, l.country] - [nil, '']).join(', '))
      l.city_id = city.id
      l.save!
    end
  end
end
