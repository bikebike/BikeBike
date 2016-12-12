class CreateCityMatches < ActiveRecord::Migration
  def change
    create_table :city_matches do |t|
      t.string :search
      t.integer :city_id

      t.timestamps null: false
    end
  end
end
