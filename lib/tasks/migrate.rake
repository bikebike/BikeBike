require 'open-uri'
require 'json'
require 'rest_client'
require 'geocoder/calculations'

namespace :migrate do
	desc "Migrates data from live site to current database"

	task users: :environment do
		migrate! User.new
	end

	task organization_statuses: :environment do
		migrate!(OrganizationStatus.new, true, 'shop_status')
		OrganizationStatus.create({:title => 'Unknown', :slug => 'unknown'})
	end

	task organizations: :environment do
		clear_table 'locations_organizations'
		clear_table 'user_organization_relationships'
		migrate! Organization.new
	end

	task conference_types: :environment do
		clear_table 'conference_types'
		ConferenceType.create({:id => 4, :title => 'Official Bike!Bike!', :slug => 'bikebike'})
		ConferenceType.create({:id => 5, :title => 'Regional Bike!Bike!', :slug => 'regional'})
		ConferenceType.create({:id => 6, :title => 'BiciCongreso', :slug => 'bici-congreso'})
	end

	task conferences: :environment do
		migrate! Conference.new
	end

	task workshops: :environment do
		migrate! Workshop.new
	end

	task conferences: :environment do
		clear_table 'conference_admins'
		clear_table 'conference_host_organizations'
		migrate! Conference.new
	end

	def migrate_user(id, object)
		if id.to_i > 0
			object.symbolize_keys!
			params =
				{
					:id => id,
					:username => object[:name],
					:email => object[:mail],
					:crypted_password => object[:pass],
					:created_at => Time.at(object[:created].to_i).to_datetime,
					:role => object[:roles].to_a.last.last.split(' ').last
				}
			return get_image(object[:picture], :avatar, params)
		end
		return nil
	end

	def migrate_organization(id, object)
		location = object[:field_location]['und'].first
		location.symbolize_keys!
		params =
			{
				:id => id,
				:name => object[:title],
				:slug => object[:path].gsub(/^.*\/(.*)$/, '\1'),
				:email_address => object[:email],
				:url => object[:field_website] && object[:field_website].first ? object[:field_website]['und'][0]['url'] : nil,
				:year_founded => object[:field_year_founded] && object[:field_year_founded].first ? object[:field_year_founded]['und'][0]['value'] : nil,
				:info => object[:body]['und'][0]['value'],
				:organization_status_id => object[:field_shop_status] && object[:field_shop_status].first ? object[:field_shop_status]['und'][0]['tid'] : nil,
				:phone => location[:phone],
				:created_at => Time.at(object[:created].to_i).to_datetime
			}
		logo = object[:field_logo] && object[:field_logo].first ? object[:field_logo]['und'].first : object[:field_icon]['und'].first
		params = get_image(logo, :avatar, params)
		params = get_panoramio_image(location[:city], location[:province], location[:country], :cover, params)
		return params
	end

	def organization_post_save(json, object)
		l = json[:field_location]['und'].first
		l.symbolize_keys!
		lparams = {
			:id => l[:lid],
			:title => l[:name],
			:latitude => l[:latitude],
			:longitude => l[:longitude],
			:longitude => l[:longitude],
			:country => l[:country].upcase,
			:territory => l[:province].upcase,
			:city => l[:city],
			:street => l[:street],
			:postal_code => l[:postal_code]
		}
		location = nil
		begin
			location = Location.create(lparams)
		rescue
			location = Location.find(l[:lid])
			location.update_attributes(lparams)
		end

		object.locations << location
		json[:field_administrators]['und'].each { |u|
			object.user_organization_relationships << UserOrganizationRelationship.new(:user_id => u['target_id'].to_i, :relationship => UserOrganizationRelationship::Administrator)
		}
		object.save!
	end

	def migrate_conference(id, object)
		host = Organization.find(object[:field_host_organizations]['und'].first['target_id'].to_i)
		location = host.locations.first
		params =
			{
				:id => id,
				:title => object[:title],
				:slug => object[:path].gsub(/^.*\/(.*)$/, '\1'),
				:conference_type_id => object[:field_conference_type] && object[:field_conference_type].first ? object[:field_conference_type]['und'][0]['tid'] : nil,
				:info => object[:body]['und'][0]['value'],
				:start_date => object[:field_date]['und'][0]['value'],
				:end_date => object[:field_date]['und'][0]['value2'],
				:workshop_schedule_published => object[:field_workshops_published]['und'][0]['value'].to_i,
				:registration_open => object[:field_registration_open]['und'][0]['value'].to_i,
				:meals_provided => object[:field_meals_provided]['und'][0]['value'].to_i,
				:meal_info => object[:field_meal_info] && object[:field_meal_info].first ? object[:field_meal_info]['und'][0]['value'] : '',
				:created_at => Time.at(object[:created].to_i).to_datetime
			}
		params = get_image(object[:field_banner]['und'].first, :poster, params)
		params = get_panoramio_image(location.city, location.territory, location.country, :cover, params)
		return params
	end

	def conference_post_save(json, object)
		object.locations << location
		i = 0
		json[:field_host_organizations]['und'].each { |u|
			object.conference_host_organizations << ConferenceHostOrganization.new(:organization_id => u['target_id'].to_i, :order => i)
			i += 1
		}
		object.save!
	end

	def migrate_organization_status(id, object)
		return {
				:id => id,
				:name => object[:name],
				:slug => object[:name].split(/\s/).first.downcase
			}
	end

	def get_image(picture, column, params)
		if picture
			params["remote_#{column.to_s}_url".to_sym] = 'https://www.bikebike.org/sites/default/files/' + picture['uri'].gsub(/^public:\/\/(.*)$/, '\1')
			params[column.to_sym] = picture['filename']
		end
		return params
	end

	def get_panoramio_image(city, territory, country, column, params)
		result = Geocoder.search(city + ', ' + (territory ? territory + ' ' : '') + country).first
		if result
			points = Geocoder::Calculations.bounding_box([result.latitude, result.longitude], 5, { :unit => :km })
			response = RestClient.get 'http://www.panoramio.com/map/get_panoramas.php', :params => {:set => :public, :size => :original, :from => 0, :to => 20, :mapfilter => false, :miny => points[0], :minx => points[1], :maxy => points[2], :maxx => points[3]}
			if response.code == 200
				JSON.parse(response.to_str)['photos'].each { |img|
					if img['width'].to_i > 980
						params["remote_#{column.to_s}_url".to_sym] = img['photo_file_url']
						params[column.to_sym] = img['photo_file_url'].gsub(/^.*\/(.*)$/, '\1')
						params[:cover_attribution_id] = img['owner_id']
						params[:cover_attribution_name] = img['owner_name']
						params[:cover_attribution_src] = 'panoramio'
						return params
					end
				}
			end
		end
		return params
	end

	def migrate!(model, vocabulary = false, table = nil)
		type = model.class.table_name
		clear_table(type)
		is_users = (type == 'users')
		table ||= type.singularize
		get_data(is_users ? 'user' : (vocabulary ? 'taxonomy_term' : 'node'), is_users || vocabulary ? nil : table, vocabulary ? table : nil).each { |id, object|
			object.symbolize_keys!
			params = self.send('migrate_' + type.singularize, id, object)
			if params
				new_object = model.class.create(params)
				post_save = (type.singularize + '_post_save')
				begin
					self.send(post_save, object, new_object)
				rescue;	end
			end
		}
	end

	def clear_table(table)
		ActiveRecord::Base.connection.execute("TRUNCATE TABLE #{table} RESTART IDENTITY;")
	end

	def get_data(entity_type, node_type = nil, vocabulary = nil)
		params = "dunhooser=#{entity_type}"
		if node_type
			params += "&actakinding=#{node_type}"
		elsif vocabulary
			params += "&folloo=#{vocabulary}"
		end
		url = "https://www.bikebike.org/reformulmatics?#{params}"
		begin
			JSON.parse(open(url).read)
		rescue
			puts url
		end
	end
end
