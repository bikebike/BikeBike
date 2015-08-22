class AddLocaleToConference < ActiveRecord::Migration
  def change
    add_column :conferences, :locale, :string
  end
end
