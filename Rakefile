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
    Rake::Task['cucumber:run'].execute
  end
end

task :css do
  ENV['CSS_TEST'] = '1'
  Rake::Task['cucumber:run'].execute
  ENV['CSS_TEST'] = nil
end

task :a11y do
  ENV['TEST_A11Y'] = '1'
  Rake::Task['cucumber:run'].execute
  ENV['TEST_A11Y'] = nil
end

task "cucumber:debug" do
  ENV['TEST_DEBUG'] = '1'
  Rake::Task['cucumber:run'].execute
  ENV['TEST_DEBUG'] = nil
end

# Cucumber::Rake::Task.new(:cucumber) do |t|
#   t.cucumber_opts = "features --format pretty"
# end

namespace :cucumber do
  directory 'tmp'
  @rerun_file = 'tmp/rerun.txt'

  Cucumber::Rake::Task.new(:all) do |task|
    task.cucumber_opts = "features --format pretty --format rerun --out tmp/rerun.txt"
  end

  desc 'Run cucumber features'
  task run: :tmp do
    retry_on_failure do
      run_features
    end
    clean_up
    exit @exit_status
  end

  def retry_on_failure
    rm_rf @rerun_file
    @retries = 0
    begin
      @exit_status = 0
      yield
    rescue SystemExit => e
      @exit_status = e.status
      if retry?(exception: e)
        @retries += 1
        retry
      end
    end
  end

  def run_features
    if File.exists? @rerun_file
      Cucumber::Rake::Task::ForkedCucumberRunner.new(['lib'], Cucumber::BINARY, [
          'features',
          '--format', 'pretty',
          '@tmp/rerun.txt',
          '--format', 'rerun',
          '--out', 'tmp/rerun.txt'
        ], true, []).run
    else
      Rake::Task['cucumber:all'].invoke
    end
  end

  def retry?(exception: nil)
    @retries < 2 && !exception.success?
  end

  def clean_up
    rm_rf @rerun_file.pathmap("%d")
  end
end
