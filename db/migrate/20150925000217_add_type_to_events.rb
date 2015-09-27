class AddTypeToEvents < ActiveRecord::Migration
  def change
    add_column :events, :event_type, :string
  end
end
