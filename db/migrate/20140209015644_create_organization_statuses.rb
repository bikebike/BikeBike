class CreateOrganizationStatuses < ActiveRecord::Migration
  def change
    create_table :organization_statuses do |t|
      t.string :name
      t.string :slug
      t.string :info

      t.timestamps
    end
  end
end
