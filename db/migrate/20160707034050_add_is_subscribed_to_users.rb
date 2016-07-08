class AddIsSubscribedToUsers < ActiveRecord::Migration
  def change
    add_column :users, :is_subscribed, :boolean
  end
end
