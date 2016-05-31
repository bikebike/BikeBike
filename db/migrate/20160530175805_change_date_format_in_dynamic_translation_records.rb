class ChangeDateFormatInDynamicTranslationRecords < ActiveRecord::Migration
  def change
  	change_column :dynamic_translation_records, :created_at, :timestamp
  end
end
