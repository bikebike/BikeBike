namespace :translations do
	desc "Migrates collected translations from the dev and testing environments"
	task migrate: :environment do
		#File.open('config/locales/.translations.yml', 'w')
		#File.open('config/locales/.translation-cache.yml', 'w+')

		translations = YAML.load(File.read('config/locales/translation-info.yml')) || Hash.new
		translations.each { |k,t| 
			if t['data']
				t['data'].each { |tt|
					hash = ActiveSupport::JSON.decode(tt)
					begin
						translation = Translation.find(hash['id'])
						translation.update_attributes(hash)
					rescue
						begin
							Translation.new(hash).save
						rescue; end
					end
				}
			end
		}
	end
end
