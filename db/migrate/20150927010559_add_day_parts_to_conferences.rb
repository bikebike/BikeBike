class AddDayPartsToConferences < ActiveRecord::Migration
  def change
    add_column :conferences, :day_parts, :string
  end
end
