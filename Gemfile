source 'http://rubygems.org'

#ruby '2.0.0'
gem 'rails', '4.0.0'
gem 'pg'
gem 'haml'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'coffee-rails', '~> 4.0.0'
gem 'i18n-active_record',
			:git => 'git://github.com/svenfuchs/i18n-active_record.git',
			:require => 'i18n/active_record'
gem 'sass-rails', '~> 4.0.0'
gem "compass-rails", "~> 1.1.3"
gem 'foundation-rails'
gem 'uglifier', '>= 1.3.0'
gem 'sorcery', '>= 0.8.1'
gem 'oauth2', '~> 0.8.0'
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
	gem 'rspec'
	gem 'rspec-rails'
end

group :development do
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
	gem 'launchy'
	gem 'selenium-webdriver'
	gem 'simplecov', require: false
	gem 'webmock', require: false
	gem 'wdm', '>= 0.1.0' if RbConfig::CONFIG['target_os'] =~ /mswin|mingw|cygwin/i
end

group :staging, :production do
	gem 'rails_12factor'
	gem 'capistrano'
	gem 'rvm-capistrano'
	gem 'unicorn' if !(RbConfig::CONFIG['target_os'] =~ /mswin|mingw|cygwin/i)
end
