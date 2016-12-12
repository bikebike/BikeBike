class ChangeConferenceDatetimesToDates < ActiveRecord::Migration
  def change
  	change_column :conferences, :start_date, :date
  	change_column :conferences, :end_date, :date
  end
end
