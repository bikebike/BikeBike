include ApplicationHelper

class PagesController < ApplicationController
    #skip_before_filter :verify_authenticity_token, only: [:translate]

	def home
        @conferences = Conference.all
		@conference = Conference.find(:first, :order => "start_date DESC")
	end

	def translate
		key = params[:translationkey]
		value = params[:translationvalue]
		if params[:auto_translate]
			if params[:translationlang] == 'en'
				value = I18n::MissingTranslationExceptionHandler.note(key)
			else
				value = I18n.backend.request_translation(key, {}, {fallback: true, locale: params[:translationlang]})
			end
		elsif params[:translationhascount] == '1'
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
			render json: {success: true, key: key, jkey: key.gsub('.', '--'), translation: I18n.translate(key, {:raise => false, :locale => params[:translationlang].to_sym})}
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

	def translations
		@lang = params[:lang]
		@translations = I18n.backend.get_translation_info
		I18n.config.enforce_available_locales = false
	end

	def translation_list
		total = 0
		complete = 0
		@completeness = Hash.new
		translation_info = I18n.backend.get_translation_info()
		translation_info.each { |k,v|
			#total += 1
			#complete += v['languages'].include?(lang.to_s) ? 1 : 0
			v['languages'].each { |l|
				@completeness[l] ||= 0
				@completeness[l] += 1
			}
		}
		#@test = total ? complete / total : 0
		@total_translations = translation_info.size()
		@language_codes = I18n.backend.get_language_codes().select { |s| s }.sort{ | a1, a2 |
			c2 = @completeness.has_key?(a2.to_s) ? @completeness[a2.to_s] : 0
			c1 = @completeness.has_key?(a1.to_s) ? @completeness[a1.to_s] : 0
			c1 == c2 ? a1 <=> a2 : c2 <=> c1
		}
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
