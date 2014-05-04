namespace :translations do
	desc "Migrates collected translations from the dev and testing environments"
	task migrate: :environment do
		#File.open('config/locales/.translations.yml', 'w')
		#File.open('config/locales/.translation-cache.yml', 'w+')

		translations = YAML.load(File.read('config/locales/.translations.yml')) || Hash.new
		translations.each { |k,t| 
			if t['data']
				t['data'].each { |tt|
					hash = ActiveSupport::JSON.decode(tt)
					translation = Translation.find(hash['id'])
					if translation
						#t.assign_attributes(hash)
						translation.update_attributes(hash)
					else
						Translation.new(hash).save
					end
				}
			end
		}
	end
end
