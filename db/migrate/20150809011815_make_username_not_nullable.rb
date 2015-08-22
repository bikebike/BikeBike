class MakeUsernameNotNullable < ActiveRecord::Migration
  def change
  	change_column :users, :username, :string, :null => false
  end
end
