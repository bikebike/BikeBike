class CreateConferenceHostOrganizations < ActiveRecord::Migration
  def change
    create_table :conference_host_organizations do |t|
      t.integer :conference_id
      t.integer :organization_id
      t.integer :order

      t.timestamps
    end
  end
end
