class AddIsFeaturedToConference < ActiveRecord::Migration
  def change
    add_column :conferences, :is_featured, :boolean

    Conference.all.each do |c|
      c.update_attribute :is_featured, (c.slug == 'Detroit2016')
    end
  end
end
