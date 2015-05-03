CarrierWave.configure do |config|
	if Rails.env == "production"
		config.asset_host = "https://cdn.bikebike.org"
	elsif Rails.env == "preview"
		config.asset_host = "https://preview-cdn.bikebike.org"
	end
end
