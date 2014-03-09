class CreateOrganizationLocations < ActiveRecord::Migration
	def change
		create_table :locations_organizations, :id => false do |t|
			t.integer :organization_id
			t.integer :location_id
		end
	end
end
