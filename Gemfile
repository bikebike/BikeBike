source 'http://rubygems.org'

gem 'rails', '4.2.0'
gem 'pg'
gem 'haml'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'coffee-rails', '~> 4.0.0'
gem 'lingua_franca', :git => 'git://github.com/lingua-franca/lingua_franca.git'
gem 'tzinfo-data'
gem 'sass', '~> 3.4.13'
gem 'sass-rails', :git => 'git://github.com/rails/sass-rails.git'
gem 'bumbleberry', :git => 'git://github.com/bumbleberry/bumbleberry.git'
gem 'foundation-rails'
gem 'uglifier', '>= 1.3.0'
gem 'sorcery', '>= 0.8.1'
gem 'oauth2', '~> 0.8.0'
gem 'carrierwave'
gem 'carrierwave-imageoptimizer'
gem 'mini_magick'
gem 'nested_form'
gem 'acts_as_list'
gem 'geocoder'
gem 'paper_trail', '~> 3.0.5'
gem 'font-awesome-rails'
gem 'wysiwyg-rails'
gem 'rails-assets-cdn'
gem 'sitemap_generator'
gem 'activerecord-session_store'
gem 'paypal-express', '0.7.1'
gem 'sass-json-vars'

gem 'copydb'

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
end

group :test do
	gem 'capybara'
    gem 'poltergeist'
	gem 'guard-rspec'
	gem 'factory_girl_rails'
	gem 'coveralls', require: false
	gem 'launchy'
	gem 'selenium-webdriver'
	gem 'simplecov', require: false
	gem 'webmock', require: false
	gem 'cucumber-rails', :require => false
	gem 'database_cleaner'
end

group :staging, :production do
	gem 'rails_12factor'
	gem 'capistrano'
	gem 'rvm-capistrano'
end

platforms 'mswin', 'mingw' do
	group :test do
		gem 'wdm', '>= 0.1.0'
	end

	group :staging, :production do
		gem 'unicorn' if !(RbConfig::CONFIG['target_os'] =~ /mswin|mingw|cygwin/i)
	end
end
