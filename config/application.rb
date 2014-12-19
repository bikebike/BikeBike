require File.expand_path('../boot', __FILE__)

require 'rails/all'
#require "#{Rails.root}/app/helpers/bike_bike_form_helper"
#require '/app/helpers/bike_bike_form_helper.rb'
#require 'dotenv'; Dotenv.load ".env.local", ".env.#{Rails.env}"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

ENV['JPEGOPTIM_BIN'] = 'jpegoptim'
ENV['OPTIPNG_BIN'] = 'optipng'

module BikeBike
	class Application < Rails::Application
		# Settings in config/environments/* take precedence over those specified here.
		# Application configuration should go into files in config/initializers
		# -- all .rb files in that directory are automatically loaded.

		# Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
		# Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
		# config.time_zone = 'Central Time (US & Canada)'

		# The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
		# config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
		config.i18n.default_locale = :en
		config.i18n.enforce_available_locales = false
		self.paths['config/database'] = Rails.root.parent.join('BikeBike', 'config', 'database.yml')
	end
end
