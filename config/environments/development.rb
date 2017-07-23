#require 'perftools'

#OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

BikeBike::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true
  config.assets.digest = true
  config.assets.compile = true
  config.assets.precompile += %w(*.png *.jpg *.jpeg *.gif *.json *.ttf *.otf *.woff *.woff2 *.svg *.json)

  # to deliver to the browser instead of email
  config.action_mailer.delivery_method = :letter_opener
  # config.action_mailer.delivery_method = :smtp
  # config.action_mailer.smtp_settings = {
  #   address: 'smtp.gmail.com',
  #   domain: 'bikebike.org',
  #   port: 587,
  #   authentication: :plain,
  #   enable_starttls_auto: true,
  #   openssl_verify_mode: 'none',
  #   user_name: 'info@bikebike.org',
  #   password: 'Toronto@)!)'
  # }
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_deliveries = true

  config.serve_static_files = true
  # config.action_controller.perform_caching = true

  I18n.config.language_detection_method = I18n::Config::DETECT_LANGUAGE_FROM_URL_PARAM

  Paypal.sandbox!
  config.action_controller.default_url_options = { trailing_slash: true }
end
