# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.
require 'rubygems'
require 'cucumber'
require 'cucumber/rake/task'

require File.expand_path('../config/application', __FILE__)

BikeBike::Application.load_tasks

task regenerate_images: :environment do
  {
    conference: [ :cover, :poster ],
    organization: [ :logo, :avatar, :cover ]
  }.each do | model_class, attributes |
    Object.const_get(model_class.to_s.titlecase).all.each do | model |
      attributes.each do | attribute |
        uploader = model.send(attribute)
        if uploader.present?
          puts "Regenerating #{model_class}.#{attribute} = #{uploader.url}"
          uploader.recreate_versions!
        end
      end
    end
  end
end

task update_cities: :environment do
  Location.all.each do |l|
    s = ([l.city, l.territory, l.country] - [nil, '']).join(', ')
    unless l.city_id.present?
      begin
        puts "Searching for #{s}"
        city = City.search(s)
        l.city_id = city.id
        l.save!
      rescue
        puts "Error searching for #{s}"
      end
    end
  end

  City.all.each do |c|
    unless c.place_id.present?
      location = Geocoder.search(c.address, language: 'en').first
      c.place_id = location.data['place_id']
      c.save!
    end
  end
end

task update_cities_es: :environment do
  City.all.each do |c|
    city = c.get_translation(:es)
    c.set_column_for_locale(:city, :es, city, 0) unless city.blank? || city == c.get_column_for_locale(:city, :es)
    c.save!
  end
end

task update_cities_fr: :environment do
  City.all.each do |c|
    city = c.get_translation(:fr)
    c.set_column_for_locale(:city, :fr, city, 0) unless city.blank? || city == c.get_column_for_locale(:city, :fr)
    c.save!
  end
end

task :i18n do
  LinguaFranca.test LinguaFranca::TestModes::RECORD do
    Rake::Task[:cucumber].execute
  end
end

task :css do
  ENV['CSS_TEST'] = '1'
  Rake::Task[:cucumber].execute
  ENV['CSS_TEST'] = nil
end

task :a11y do
  ENV['TEST_A11Y'] = '1'
  Rake::Task[:cucumber].execute
  ENV['TEST_A11Y'] = nil
end

task "cucumber:debug" do
  ENV['TEST_DEBUG'] = '1'
  Rake::Task[:cucumber].execute
  ENV['TEST_DEBUG'] = nil
end

Cucumber::Rake::Task.new(:cucumber) do |t|
  t.cucumber_opts = "features --format pretty"
end
