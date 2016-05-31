class AddLanguagesToUsers < ActiveRecord::Migration
  def change
    add_column :users, :languages, :json
  end
end
