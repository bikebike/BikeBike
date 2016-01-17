source 'http://rubygems.org'

gem 'rails', '4.2.0'
gem 'pg'
gem 'haml'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'coffee-rails', '~> 4.0.0'

if Dir.exists?('../lingua_franca')
	gem 'lingua_franca', :path => '../lingua_franca'
else
	gem 'lingua_franca', :git => 'git://github.com/lingua-franca/lingua_franca.git'
end

#if Dir.exists?('../lingua_franca_commit_and_deploy')
#	gem 'lingua_franca_commit_and_deploy', :path => '../lingua_franca_commit_and_deploy'
#else
#	gem 'lingua_franca_commit_and_deploy', :git => 'git://github.com/lingua-franca/lingua_franca_commit_and_deploy.git'
#end

gem 'tzinfo-data'
gem 'sass'#, '~> 3.4.13'
gem 'sass-rails'

if Dir.exists?('../bumbleberry')
	gem 'bumbleberry', :path => "../bumbleberry"
else
	gem 'bumbleberry', :git => 'git://github.com/bumbleberry/bumbleberry.git'
end

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
gem 'sitemap_generator'
gem 'activerecord-session_store'
gem 'paypal-express', '0.7.1'
gem 'sass-json-vars'
gem 'delayed_job_active_record'
gem 'redcarpet'

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
	gem 'gherkin3', '>= 3.1.0'
	gem 'cucumber', :git => "git://github.com/cucumber/cucumber-ruby.git", branch: "integrate-gherkin3-parser"
	gem 'cucumber-core', :git => "git://github.com/cucumber/cucumber-ruby-core.git", branch: "integrate-gherkin3-parser"
	gem 'cucumber-rails', :git => "git://github.com/cucumber/cucumber-rails.git", require: false

	#gem 'capybara'
    gem 'poltergeist'
	gem 'guard-rspec'
	gem 'factory_girl_rails'
	gem 'coveralls', require: false
	gem 'launchy'
	gem 'selenium-webdriver'
	gem 'simplecov', require: false
	gem 'webmock', require: false
	#gem 'cucumber-rails', :require => false
	gem 'database_cleaner'
	gem 'mocha'
end

group :staging, :production, :preview do
	gem 'rails_12factor'
	gem 'capistrano'
	gem 'rvm-capistrano'
end

group :production, :preview do
	gem 'unicorn'
	gem 'daemon-spawn'
	gem 'daemons'
end

platforms 'mswin', 'mingw' do
	group :test do
		gem 'wdm', '>= 0.1.0'
	end
end
