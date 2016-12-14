class CityCache < ActiveRecord::Base
  self.table_name = :city_cache

  belongs_to :city

  def self.search(str)
    CityCache.find_by_search(str.downcase)
  end

  def self.cache(str, city_id)
  	CityCache.create(city_id: city_id, search: str.downcase)
  end
end
