# config/initializers/geocoder.rb
config = {
  # geocoding service (see below for supported options):
  lookup: :google,

  # IP address geocoding service (see below for supported options):
  ip_lookup: :freegeoip,

  # to use an API key:

  # geocoding service request timeout, in seconds (default 3):
  timeout: 5,

  # set default units to kilometers:
  units: :km
}

# use our api key on the server
if Rails.env.preview? || Rails.env.production?
  config[:api_key] = "AIzaSyDurfjX9f_NgYsJLyUuGqwdKuI745CE_OE"
  config[:use_https] = true
end

Geocoder.configure(config)
