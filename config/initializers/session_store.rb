# Be sure to restart your server when you modify this file.

if Rails.env == 'production' || Rails.env == 'preview'
	BikeBike::Application.config.session_store :active_record_store, :domain => 'bikebike.org'
else
	BikeBike::Application.config.session_store :active_record_store
end
