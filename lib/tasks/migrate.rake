require 'open-uri'
require 'json'
require 'rest_client'
require 'geocoder/calculations'

$panoramios = Hash.new

namespace :migrate do
	desc "Migrates data from live site to current database"

	task all: :environment do
		puts ""
		Dir.glob(File.join(File.dirname(__FILE__), 'sample_data', "*.yml")).each { | file|
			class_name = file.gsub(/^.*\/(.*?).yml$/, '\1').classify
			object = nil
			begin
				object = class_name.constantize.new
			rescue
				puts "\tUndefined class: #{class_name}"
			end
			if object
				puts "\tMigrating #{class_name} objects"
				migrate! object
			end
		}
		puts "\tMigration complete"
		puts ""
	end

	task users: :environment do
		migrate! User.new
	end

	task locations: :environment do
		migrate! Location.new
	end

	task organization_statuses: :environment do
		migrate! OrganizationStatus.new#, true, 'shop_status'
	end

	task organizations: :environment do
		migrate! Organization.new
	end
	
	task conference_types: :environment do
		migrate! ConferenceType.new#, true, false
	end

	task conferences: :environment do
		migrate! Conference.new
	end
	
	task workshop_streams: :environment do
		migrate! WorkshopStream.new#, true
	end

	task workshop_resources: :environment do
		migrate! WorkshopResources.new#, true
	end

	task workshops: :environment do
		migrate! Workshop.new
	end

	def clear_table(table)
		ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table} RESTART IDENTITY;")
	end

	def get(type, key = nil)
		file = File.join(File.dirname(__FILE__), 'sample_data', "#{type}.yml")
		if File.exist?(file)
			data = YAML.load_file(file)
			if key
				return data[key]
			end
			return data
		end
		[]
	end

	def prepare_user(user)
		return user
	end
	
	def prepare_organizations
		clear_table('organization_statuses')
		clear_table('user_organization_relationships')
	end

	def prepare_organization(org)
		org['users'].each { | key, relationship |
			user = get('users', key)
			UserOrganizationRelationship.create({
				user_id: user['id'].to_i,
				organization_id: org['id'].to_i,
				relationship: relationship
			})
		}
		status = get('organization_statuses', org['organization_status'])
		org['organization_status_id'] = status['id'].to_i

		org.delete('users')
		org.delete('organization_status')
		return org
	end

	def call(fn, args = [])
		if self.respond_to?(fn, true)
			object = self.send(fn, *args)
		end
	end

	def migrate!(model)
		type = model.class.table_name
		clear_table(type)

		call("prepare_#{type}")

		data = get(type)

		data.each { | key, object |
			call("prepare_#{type.singularize}", [object])
			record = model.class.create(object)
		}
	end
end
