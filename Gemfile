source 'http://rubygems.org'

ruby '2.0.0'
gem 'rails', '4.0.0'

# Servers
# gem 'puma'
# gem 'unicorn'
# gem 'openssl', '~> 1.1.0'

gem 'eventmachine'

# Multi-environment configuration
# gem 'simpleconfig'

# API
# gem 'rabl'

# ORM
gem 'pg'

# Security
# gem 'secure_headers'
#gem 'dotenv-rails', :groups => [:development, :test]

# Miscellanea
# gem 'google-analytics-rails'
gem 'haml'
# gem 'http_accept_language'
gem 'jquery-rails'
gem 'jquery-ui-rails'
# gem 'resque', require: 'resque/server' # Resque web interface

# Assets
gem 'coffee-rails', '~> 4.0.0'
gem 'haml_assets'
gem 'handlebars_assets'
gem 'i18n-js'
gem 'i18n-active_record',
			:git => 'git://github.com/svenfuchs/i18n-active_record.git',
			:require => 'i18n/active_record'
gem 'jquery-turbolinks'
gem 'sass-rails', '~> 4.0.0'
gem "compass-rails", "~> 1.1.3"
gem 'foundation-rails'
#gem 'turbolinks' # This would be great to have working, right now lets focus on gettting it working without it.
gem 'uglifier', '>= 1.3.0'
gem 'sorcery', '>= 0.8.1'
gem 'oauth2', '~> 0.8.0'
gem 'ruby-drupal-hash'
gem 'redis'
gem 'carrierwave'
gem 'carrierwave-imageoptimizer'
gem 'mini_magick'
gem 'carmen', :path => '../carmen/' if File.directory?('../carmen/') && RbConfig::CONFIG['target_os'] =~ /mswin|mingw|cygwin/i
gem 'carmen-rails'
gem 'nested_form'
gem 'acts_as_list'

gem 'geocoder'
gem 'forgery'
gem 'paper_trail'


group :development, :test do
	gem 'debugger'
	gem 'delorean'
	gem 'rspec'
	gem 'rspec-rails'
end

group :development do
  gem 'bullet'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'
  gem 'haml-rails'
  gem 'awesome_print'
  gem 'rails-footnotes', :github => 'josevalim/rails-footnotes'
end

group :test do
	gem 'capybara'
	gem 'guard-rspec'
	gem 'factory_girl_rails'
	gem 'coveralls', require: false
	gem 'database_cleaner'
	gem 'email_spec'
	gem 'launchy'
	gem 'selenium-webdriver'
	gem 'simplecov', require: false
	gem 'webmock', require: false
	gem 'wdm', '>= 0.1.0' if RbConfig::CONFIG['target_os'] =~ /mswin|mingw|cygwin/i
end

group :staging, :production do
	gem 'rails_12factor'
end
