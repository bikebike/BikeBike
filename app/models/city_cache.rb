class CityCache < ActiveRecord::Base
  self.table_name = :city_cache

  belongs_to :city

  # look for a term to see if its already been searched for
  def self.search(str)
    CityCache.find_by_search(normalize_string(str))
  end

  # cache this search term
  def self.cache(str, city_id)
  	CityCache.create(city_id: city_id, search: normalize_string(str))
  end
  
  private
    def normalize_string(str)
      # remove accents, unnecessary whitespace, punctuation, and lowcase tje string
      I18n.transliterate(str).gsub(/[^\w\s]/, '').gsub(/\s\s+/, ' ').strip.downcase
    end
end
