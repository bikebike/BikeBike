class AddProviderConditionsToConference < ActiveRecord::Migration
  def change
    add_column :conferences, :provider_conditions, :json
  end
end
