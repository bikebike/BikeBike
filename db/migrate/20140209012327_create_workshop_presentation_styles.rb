class CreateWorkshopPresentationStyles < ActiveRecord::Migration
  def change
    create_table :workshop_presentation_styles do |t|
      t.string :name
      t.string :slug
      t.string :info

      t.timestamps
    end
  end
end
