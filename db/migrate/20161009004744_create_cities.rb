class CreateCities < ActiveRecord::Migration
  def change
    create_table :cities do |t|
      t.string :city
      t.string :territory
      t.string :country
      t.float :latitude
      t.float :longitude
      t.string :locale

      t.timestamps null: false
    end
  end
end
