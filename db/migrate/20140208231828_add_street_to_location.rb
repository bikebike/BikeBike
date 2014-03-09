class AddStreetToLocation < ActiveRecord::Migration
  def change
    add_column :locations, :street, :string
  end
end
