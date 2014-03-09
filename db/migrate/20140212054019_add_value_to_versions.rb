class AddValueToVersions < ActiveRecord::Migration
  def change
    add_column :versions, :value, :string
  end
end
