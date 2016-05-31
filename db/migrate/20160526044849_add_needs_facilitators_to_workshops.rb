class AddNeedsFacilitatorsToWorkshops < ActiveRecord::Migration
  def change
    add_column :workshops, :needs_facilitators, :boolean
  end
end
