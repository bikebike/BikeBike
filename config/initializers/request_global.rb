module Rack
	class MethodOverrideWithParams < Rack::MethodOverride
		def call(env)
			#puts "\n\nENV: " + env.to_json.to_s + "\n\n"
			#puts "\n\nTT: "
			#puts I18n::Backend::BikeBike.translations_file + "\n\n"
			$request = Rack::Request.new(env)
			#Rails.I18n.translations_file ||= 'config/locales/.translations.yml'
			#if Rails.env.test?
			#	File.open(Rails.I18n.translations_file, 'w+')# { |f| f.write {}.to_yaml }
			#end
			super(env)
		end
	end
end
