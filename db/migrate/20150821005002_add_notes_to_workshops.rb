class AddNotesToWorkshops < ActiveRecord::Migration
  def change
    add_column :workshops, :notes, :text
  end
end
