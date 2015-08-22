class AddLanguagesToWorkshops < ActiveRecord::Migration
  def change
    add_column :workshops, :languages, :string
    add_column :workshops, :needs, :string
    add_column :workshops, :space, :string
    add_column :workshops, :theme, :string
    add_column :workshops, :host_info, :text
  end
end
