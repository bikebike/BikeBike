include ApplicationHelper
require 'uri'

class OrganizationsController < ApplicationController
	before_action :set_organization, only: [:show, :edit, :update, :destroy]

	before_filter :require_login, :except => [:index, :show]

	# GET /organizations
	def index
		@organizations = Organization.all
	end

	# GET /organizations/1
	def show
		if params[:slug] == 'json'
			json
		end
	end

	# GET /organizations/new
	def new
		@organization = Organization.new
		#@organization.location = Location.new
		@organization.locations.build
		@user_location = lookup_ip_location
		@organization.locations[0].city = @user_location.city
		@organization.locations[0].country = @user_location.country_code
		@organization.locations[0].territory = @user_location.state_code
		@organization.locations_organization.build
		@organization.user_organization_relationships.build
	end

	# GET /organizations/1/edit
	def edit
	end

	# POST /organizations
	def create
		@organization = Organization.new(organization_params)
		params[:organization][:locations_attributes].each do |k, v|
			@organization.locations << Location.new(locations_organization_params(k))
		end
		@organization.user_organization_relationships << UserOrganizationRelationship.new(:user_id => current_user.id, :relationship => UserOrganizationRelationship::Administrator)

		if @organization.save!
			redirect_to @organization, notice: 'Organization was successfully created.'
		else
			render action: 'new'
		end
	end

	# PATCH/PUT /organizations/1
	def update
		if @organization.update_attributes(organization_params)
			redirect_to @organization, notice: 'Organization was successfully updated.'
		else
			render action: 'edit'
		end
	end

	# DELETE /organizations/1
	def destroy
		@organization.destroy
		redirect_to organizations_url, notice: 'Organization was successfully destroyed.'
	end

	def members
		set_organization
		@organization.user_organization_relationships.build
	end

	def nonmembers
		set_organization
		#puts "\n\tPARAMS: " + params[:addedUsers].to_json.to_s + "\n"
		@available_users = User.where(["id NOT IN (?)", @organization.users.map(&:id) + (params[:added] || [])])
		html = '<h2>Select a User</h2><div id="select-user-list">'
		@available_users.each do |user|
			html += '<a href="#" class="user-preview" data-id="' + user.id.to_s + '"><img src="' + (user.avatar.url :thumb) + '" /><div class="username">' + (user.username) + '</div></a>'
		end
		render :text => (html + '</div>')
	end

	def identity
		set_organization
	end

	def json
		orgs = Hash.new
		order = 0
		countries = Hash.new
		Organization.find(:all, :joins => :locations, :order => 'locations.latitude').each { |org|
			location = org.locations.first
			if !orgs.has_key?(location.country.downcase)
				orgs[location.country.downcase] = Hash.new
				countries[location.country.downcase] = { :country => Carmen::Country.coded(location.country), :territories => Hash.new }
			end
			country = countries[location.country.downcase][:country]
			if !orgs[location.country.downcase].has_key?(location.territory.downcase)
				orgs[location.country.downcase][location.territory.downcase] = Hash.new
				countries[location.country.downcase][:territories][location.territory.downcase] = country.subregions.coded(location.territory)
			end
			territory = countries[location.country.downcase][:territories][location.territory.downcase]
            city = URI.encode(location.city.downcase.gsub(/\s/, '-'))
			if !orgs[location.country.downcase][location.territory.downcase].has_key?(city)
				orgs[location.country.downcase][location.territory.downcase][city] = Hash.new
				orgs[location.country.downcase][location.territory.downcase][city][:latitude] = location.latitude
				orgs[location.country.downcase][location.territory.downcase][city][:longitude] = location.longitude
				orgs[location.country.downcase][location.territory.downcase][city][:count] = 0
			end
			orgs[location.country.downcase][location.territory.downcase][city][orgs[location.country.downcase][location.territory.downcase][city][:count]] = { 
				:title 		=> org.name,
				:id			=> org.id,
				:logo		=> org.avatar.url(:thumb),
				:logo_large	=> org.avatar.url,
				:location	=> {
					:street			=> location.street,
					:city			=> location.city,
					:province		=> location.territory,
					:country		=> country.name,
					:province_name	=> territory ? territory.name : nil,
					:country_name	=> country.name,
					:latitude		=> location.latitude,
					:longitude		=> location.longitude
				},
				:website		=> org.url,
				:year_founded	=> org.year_founded,
				:url			=> url_for(org),
				:order			=> order
			}
			orgs[location.country.downcase][location.territory.downcase][city][:count] += 1
			order += 1
		}
		render :json => orgs.to_json
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_organization
            if params[:slug] != 'json'
                @organization = Organization.find_by!(slug: params[:slug] || params[:organization_slug])
            end
		end

		# Only allow a trusted parameter "white list" through.
		def organization_params
			params.require(:organization).permit(:name, :slug, :email_address, :url, :year_founded, :info, :logo, :avatar, :cover, :requires_approval, :secret_question, :secret_answer, user_organization_relationships_attributes: [:id, :user_id, :relationship, :_destroy], locations: [:country, :territory, :city, :street, :postal_code])
		end

		def locations_organization_params(index)
			params[:organization][:locations_attributes].require(index.to_s).permit(:country, :territory, :city, :street, :postal_code)
		end

		def user_organization_params(index)
			params[:organization][:user_organization_relationships_attributes].require(index.to_s).permit(:user_id, :relationship)
		end
end
