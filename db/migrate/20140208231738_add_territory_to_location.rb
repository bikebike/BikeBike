class AddTerritoryToLocation < ActiveRecord::Migration
  def change
    add_column :locations, :territory, :string
  end
end
