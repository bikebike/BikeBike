class AddSlugToConferenceType < ActiveRecord::Migration
  def change
    add_column :conference_types, :slug, :string
  end
end
