class AddTypeToConference < ActiveRecord::Migration
  def change
    add_column :conferences, :type, :string
  end
end
