class AddIsPublicToConference < ActiveRecord::Migration
  def change
    add_column :conferences, :is_public, :boolean
    
    Conference.all.each do |c|
      c.update_attribute :is_public, true
    end
  end
end
