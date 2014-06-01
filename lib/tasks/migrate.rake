require 'open-uri'
require 'json'
require 'rest_client'
require 'geocoder/calculations'

$panoramios = Hash.new

namespace :migrate do
	desc "Migrates data from live site to current database"

	task all: :environment do
		migrate! User.new
		migrate! Location.new
		migrate! OrganizationStatus.new, true, 'shop_status'
		migrate! Organization.new
		migrate! ConferenceType.new, true, false
		migrate! Conference.new
		migrate! WorkshopStream.new, true
		migrate! WorkshopResource.new, true
		migrate! Workshop.new, true
	end

	task users: :environment do
		migrate! User.new
	end

	task locations: :environment do
		migrate! Location.new
	end

	task organization_statuses: :environment do
		migrate! OrganizationStatus.new, true, 'shop_status'
	end

	task organizations: :environment do
		migrate! Organization.new
	end
	
	task conference_types: :environment do
		migrate! ConferenceType.new, true, false
	end

	task conferences: :environment do
		migrate! Conference.new
	end
	
	task workshop_streams: :environment do
		migrate! WorkshopStream.new, true
	end

	task workshop_resources: :environment do
		migrate! WorkshopResources.new, true
	end

	task workshops: :environment do
		migrate! Workshop.new
	end

	def migrate_location(id, object)
		return {
			:id => id,
			:title => object[:name].length > 0 ? object[:name] : nil,
			:latitude => object[:latitude],
			:longitude => object[:longitude],
			:longitude => object[:longitude],
			:country => object[:country].upcase,
			:territory => object[:province].upcase,
			:city => object[:city],
			:street => object[:street],
			:postal_code => object[:postal_code].length > 0 ? object[:postal_code] : nil,
		}
	end

	def organization_statuses_post_migrate()
		OrganizationStatus.create({:id => 4, :name => 'Unknown', :slug => 'unknown'})
	end

	def organizations_pre_migrate()
		clear_table 'locations_organizations'
		clear_table 'user_organization_relationships'
	end

	def conference_types_post_migrate()
		ConferenceType.create({:id => 4, :title => 'Official Bike!Bike!', :slug => 'bikebike'})
		ConferenceType.create({:id => 5, :title => 'Regional Bike!Bike!', :slug => 'regional'})
		ConferenceType.create({:id => 6, :title => 'BiciCongreso', :slug => 'bici-congreso'})
	end

	def conferences_pre_migrate()
		clear_table 'conference_admins'
		clear_table 'conference_host_organizations'
	end

	def workshops_pre_migrate()
		clear_table 'workshop_facilitators'
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
				:email_address => object[:email] && object[:email].first ? object[:email]['und'][0]['url'] : nil,
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
				:slug => object[:path].gsub(/^.*\/(.*)$/, '\1').gsub(/\./, ''),
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

	def migrate_workshop(id, object)
		return {
				:id => id,
				:title => object[:title],
				:slug => object[:path].gsub(/^.*\/(.*)$/, '\1').gsub(/\./, ''),
				:info => object[:body]['und'][0]['value'],
				:start_time => object[:field_scheduled_time]['und'][0]['value'],
				:end_time => object[:field_scheduled_time]['und'][0]['value2'],
				:location_id => object[:field_lid] && object[:field_lid].first ? object[:field_lid]['und'][0]['value'] : nil,
				:workshop_stream_id => object[:field_stream] && object[:field_stream].first ? object[:field_stream]['und'][0]['tid'] : nil,
				:created_at => Time.at(object[:created].to_i).to_datetime
			}
	end

	def workshop_post_save(json, object)
		json[:field_coordinators]['und'].each { |u|
			object.workshop_facilitators << WorkshopFacilitators.new(:user_id => u['target_id'].to_i, :role => 'administrator')
		}
		object.save!
	end

	def migrate_workshop_resource(id, object)
		return {
				:id => id,
				:name => object[:name],
				:slug => object[:name].gsub(/[\/\-]/, '').gsub(/\s+/, '_').downcase
			}
	end

	def migrate_workshop_stream(id, object)
		return {
				:id => id,
				:name => object[:name],
				:slug => object[:name].gsub(/[\/\-]/, '').gsub(/\s+/, '_').downcase
			}
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
		location = city + ', ' + (territory ? territory + ' ' : '') + country
		$panoramios ||= Hash.new
		$panoramios[location] ||= 0
		$panoramios[location] += 1
		result = Geocoder.search(location).first
		if result
			points = Geocoder::Calculations.bounding_box([result.latitude, result.longitude], 5, { :unit => :km })
			response = RestClient.get 'http://www.panoramio.com/map/get_panoramas.php', :params => {:set => :public, :size => :original, :from => 0, :to => 20, :mapfilter => false, :miny => points[0], :minx => points[1], :maxy => points[2], :maxx => points[3]}
			if response.code == 200
				i = 0
				JSON.parse(response.to_str)['photos'].each { |img|
					if img['width'].to_i > 980
						i += 1
						if i >= $panoramios[location]
							params["remote_#{column.to_s}_url".to_sym] = img['photo_file_url']
							params[column.to_sym] = img['photo_file_url'].gsub(/^.*\/(.*)$/, '\1')
							params[:cover_attribution_id] = img['owner_id']
							params[:cover_attribution_name] = img['owner_name']
							params[:cover_attribution_src] = 'panoramio'
							return params
						end
					end
				}
			end
		end
		return params
	end

	def migrate!(model, vocabulary = false, table = nil)
		type = model.class.table_name
		clear_table(type)
		begin
			self.send(type + '_pre_migrate')
		rescue;	end
		is_entity = (type == 'users' || type == 'locations')
		if table != false
			table ||= type.singularize
			data = nil
			attempts = 0
			while !data && attempts < 10
				if attempts > 0
					sleep 2
					puts "Download failed, attempt #{attempt + 1} to obtain #{type.singularize} data from live server"
				end
				begin
					data = get_data(is_entity ? type.singularize : (vocabulary ? 'taxonomy_term' : 'node'), is_entity || vocabulary ? nil : table, vocabulary ? table : nil)
				rescue; end
				attempts += 1
			end
			if data
				data.each { |id, object|
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
			else
				puts "All attempts to access infomation from live server have failed"
			end
		end
		begin
			self.send(type + '_post_migrate')
		rescue;	end
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
