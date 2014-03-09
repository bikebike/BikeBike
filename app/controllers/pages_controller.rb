require 'rubygems'
require 'ruby_drupal_hash'

include ApplicationHelper

class PagesController < ApplicationController

	def home
		#password = ""
		#hash = ""
		#@testResult = RubyDrupalHash::verify(password, hash)
	end

	def translate
		key = params[:translationkey]
		value = params[:translationvalue]
		if params[:translationhascount] == '1'
			['zero', 'one', 'two', 'few', 'many'].each { |c|
				if params['translationpluralization_' + c]
					if !value.is_a?(Hash)
						value = Hash.new
					end
					value[c] = params['translationvalue_' + c]
				else
					Translation.destroy_all(:locale => params[:translationlang], :key => (key + '.' + c))
				end
			}
			if value.is_a?(Hash)
				value['other'] = params[:translationvalue]
				Translation.destroy_all(:locale => params[:translationlang], :key => key)
			else
				Translation.destroy_all(:locale => params[:translationlang], :key => (key + '.other'))
			end
		end
		store_translations(params[:translationlang], {key => value}, :escape => false)
		begin
			render json: {success: true, key: key, jkey: key.gsub('.', '--'), translation: I18n.translate!(key, {:raise => false})}
		rescue
			render json: {error: 'Failed to load translation'}
		end
	end

    def location_territories
        #render json: (Carmen:::RegionCollection.new(Carmen::Country.coded(params[:country])) || []).to_json
        territories = {}
        Carmen::Country.coded(params[:country]).subregions.each { |t| territories[t.code] = t.name }
        render json: territories.to_json
    end

  private
	def store_translations(locale, data, options = {})
		escape = options.fetch(:escape, true)
		I18n.backend.flatten_translations(locale, data, escape, false).each do |key, value|
			t = Translation.find_or_create_by!(locale: locale.to_s, key: key.to_s)
			t.value = value
			t.save
		end
		I18n.backend.reload!
	end
end
