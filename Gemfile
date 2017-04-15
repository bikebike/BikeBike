source 'http://rubygems.org'

gem 'rails', '4.2.0'
gem 'pg'
gem 'rake', '11.1.2'
gem 'ruby_dep', '1.3.1' # Lock at 1.3.1 since 1.4 requires ruby 2.5. We should unlock once we upgrade the ruby version on our server

gem 'rack-mini-profiler'

gem 'haml'
gem 'nokogiri', '~> 1.6.8.rc2'

gem 'tzinfo-data'
gem 'sass'
gem 'sass-rails'
gem 'uglifier', '>= 1.3.0'
# replace this once these changes are merged in sorcery
gem 'sorcery', git: 'https://github.com/tg90nor/sorcery.git', branch: 'make-facebook-provider-use-json-token-parser'
gem 'carrierwave'
gem 'carrierwave-imageoptimizer'
gem 'mini_magick'
gem 'activerecord-session_store'
gem 'premailer-rails'
gem 'sidekiq'
gem 'letter_opener'
gem 'launchy'

# Bike Collectives gems, when developing locally execute:
#   bundle config local.bikecollectives_core ../bikecollectives_core
#   bundle config local.bumbleberry ../bumbleberry
#   bundle config local.lingua_franca ../lingua_franca
#   bundle config local.marmara ../marmara
gem 'bikecollectives_core', git: 'https://github.com/bikebike/bikecollectives_core.git', branch: 'master'
gem 'bumbleberry', git: 'https://github.com/bumbleberry/bumbleberry.git', branch: '2017'
gem 'lingua_franca', git: 'https://github.com/lingua-franca/lingua_franca.git', branch: '2017'
gem 'marmara', git: 'https://github.com/lingua-franca/marmara.git', branch: 'master'

# Bike!Bike! specific stuff
gem 'paypal-express', git: 'https://github.com/ianfleeton/paypal-express'
gem 'geocoder'
gem 'sitemap_generator'
gem 'sass-json-vars'
gem 'redcarpet'
gem 'to_spreadsheet', git: 'https://github.com/glebm/to_spreadsheet.git'

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'
  
  gem 'capistrano', '~> 3.1'
  gem 'capistrano-rails', '~> 1.1'
  gem 'capistrano-faster-assets', '~> 1.0'

  gem 'eventmachine', git: 'https://github.com/krzcho/eventmachine', :branch => 'master'
  gem 'thin'# , :github => 'krzcho/thin', :branch => 'master'
  gem 'rubocop', require: false
  gem 'haml-lint', require: false
end

group :test do
  gem 'rspec'
  gem 'rspec-rails'
  gem 'gherkin3', '>= 3.1.0'
  gem 'cucumber'
  gem 'cucumber-core'
  gem 'cucumber-rails', require: false
  gem 'guard-cucumber'

  gem 'poltergeist'
  gem 'capybara-email'
  # gem 'capybara-webkit'
  gem 'guard-rspec'
  gem 'factory_girl_rails'
  gem 'coveralls', require: false
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
  gem 'webmock', require: false
  gem 'database_cleaner'
  gem 'mocha'
end

group :staging, :production, :preview do
  gem 'rails_12factor'
end

group :production, :preview do
  gem 'unicorn', require: false
  gem 'daemon-spawn'
  gem 'daemons'
end

platforms 'mswin', 'mingw' do
  group :test do
    gem 'wdm', '>= 0.1.0'
    gem 'win32console', require: false
  end
end
