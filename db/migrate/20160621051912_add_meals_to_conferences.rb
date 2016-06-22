class AddMealsToConferences < ActiveRecord::Migration
  def change
    add_column :conferences, :meals, :json
  end
end
