class AddYearToConference < ActiveRecord::Migration
  def change
    add_column :conferences, :year, :integer
  end
end
