namespace :translations do
	desc "Migrates collected translations from the dev and testing environments"
	task migrate: :environment do
		#File.open('config/locales/.translations.yml', 'w')
		#File.open('config/locales/.translation-cache.yml', 'w+')

		translations = YAML.load(File.read('config/locales/.translations.yml')) || Hash.new
		translations.each { |k,t| 
			if t['data']
				t['data'].each { |tt| tt.save }
			end
		}
	end
end
