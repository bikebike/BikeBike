class AddSpanishCityTranslations < ActiveRecord::Migration
  def change
    City.all.each do |c|
      city = c.get_translation(:es)
      c.set_column_for_locale(:city, :es, city, 0) unless city.blank? || city == c.get_column_for_locale(:city, :es)
      c.save!
    end
  end
end
