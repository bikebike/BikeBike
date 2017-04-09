require File.expand_path('../boot', __FILE__)

require 'rails/all'

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
    config.action_controller.default_url_options = { :trailing_slash => true }
    config.i18n.default_locale = :en
    config.i18n.enforce_available_locales = false
    self.paths['config/database'] = Rails.root.join('config', 'database.yml')
    config.active_record.raise_in_transactional_callbacks = true
    config.action_mailer.raise_delivery_errors = true
    config.exceptions_app = self.routes
    I18n.config.language_threshold = 0
    
    config.paths['db/migrate'] = BikecollectivesCore::Engine.paths['db/migrate'].existent
  end
end
