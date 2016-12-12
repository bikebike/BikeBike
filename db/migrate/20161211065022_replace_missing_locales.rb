class ReplaceMissingLocales < ActiveRecord::Migration
  def change
    Conference.where(locale: nil).each do |c|
      c.update_attribute :locale, 'en'
    end

    Workshop.where(locale: nil).each do |c|
      c.update_attribute :locale, 'en'
    end

    Event.where(locale: nil).each do |c|
      c.update_attribute :locale, 'en'
    end

    City.where(locale: nil).each do |c|
      c.update_attribute :locale, 'en'
    end
  end
end
