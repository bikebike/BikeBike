CarrierWave.configure do |config|
	if Rails.env == "production"
		config.asset_host = "https://cdn.bikebike.org"
	end
end
