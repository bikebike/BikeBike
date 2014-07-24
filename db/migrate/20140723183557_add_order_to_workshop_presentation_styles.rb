class AddOrderToWorkshopPresentationStyles < ActiveRecord::Migration
  def change
    add_column :workshop_presentation_styles, :order, :integer
  end
end
