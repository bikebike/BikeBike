class AddIsTranslatorToUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_translator, :boolean
  end
end
