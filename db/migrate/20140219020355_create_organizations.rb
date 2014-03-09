class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.string :name
      t.string :slug
      t.string :email_address
      t.string :url
      t.integer :year_founded
      t.text :info
      t.string :logo
      t.string :avatar
      t.boolean :requires_approval
      t.string :secret_question
      t.string :secret_answer
      t.integer :location_id
      t.integer :user_organization_replationship_id

      t.timestamps
    end
  end
end
