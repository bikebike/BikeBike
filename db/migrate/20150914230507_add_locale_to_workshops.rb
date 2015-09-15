class AddLocaleToWorkshops < ActiveRecord::Migration
  def change
    add_column :workshops, :locale, :string
  end
end
