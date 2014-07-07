namespace :regenerate do
	desc "Regenerates images"

	task conference_posters: :environment do
		Conference.all.each {|m| m.poster.recreate_versions!}
        puts Conference.all.to_json.to_s
	end

	task organization_avatars: :environment do
		Organization.all.each {|m| m.avatar.recreate_versions!}
	end

	task conference_covers: :environment do
		Conference.all.each {|m| m.cover.recreate_versions!}
	end

	task organization_covers: :environment do
		#Organization.all.each {|m| m.cover.recreate_versions!}
        puts Rails.configuration.database_configuration[Rails.env].to_json.to_s
	end
end
