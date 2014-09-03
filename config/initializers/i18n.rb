require 'i18n/backend/active_record'
require 'yaml'

if Rails.env.test?
	class DevTranslation < Translation
		self.table_name = 'translations'
		establish_connection :development
	end
end

module I18n
	class MissingTranslationExceptionHandler < ExceptionHandler
		def self.lorem_ipsum(method, size)
			options = {:random => true}
			case method.to_s
			when 'c', 'char', 'character', 'characters'
				if size
					return (Forgery::LoremIpsum.characters size, options).capitalize
				end
				return Forgery::LoremIpsum.character, options
			when 'w', 'word', 'words'
				if size
					return (Forgery::LoremIpsum.words size, options).capitalize
				end
				#return'LOREM'
				return (Forgery::LoremIpsum.word options).capitalize
			when 's', 'sentence', 'sentences'
				if size
					return Forgery::LoremIpsum.sentences size, options
				end
				return (Forgery::LoremIpsum.sentence options).capitalize
			when 'p', 'paragraph', 'paragraphs'
				if size
					return Forgery::LoremIpsum.paragraphs size, options.merge({:sentences => 10})
				end
				return Forgery::LoremIpsum.sentences 10, options
			when 't', 'title'
				return (Forgery::LoremIpsum.sentences 1, options).capitalize
			end
			return method
		end

		def self.note(key, behavior = nil, behavior_size = nil)
			I18n.backend.needs_translation(key)
			if behavior
				if behavior.to_s == 'strict'
					return nil
				end
				return self.lorem_ipsum(behavior, behavior_size)
			end
			#key.to_s.gsub(/^world\..*\.(.+)\.name$/, '\1').gsub(/^.*\.(.+)?$/, '\1').gsub('_', ' ')
			key.to_s.gsub(/^world\.(.+)\.name$/, '\1').gsub(/^.*\.(.+)?$/, '\1').gsub('_', ' ')
		end

		def call(exception, locale, key, options)
			if exception.is_a?(MissingTranslation)
				I18n::MissingTranslationExceptionHandler.note(key, options[:behavior] || nil, options[:behavior_size] || nil)
			else
				super
			end
		end
	end

	module Backend
		class BikeBike < I18n::Backend::ActiveRecord
			@@needs_translation

			@@translations_file = 'tmp/locales/translation-info.yml'
			@@translation_cache_file = 'tmp/locales/.translation-cache.yml'
			@@pluralization_rules_file = 'config/locales/pluralization-rules.yml'
			@@translation_cache
			@@testing_started = false
			@@hosts

			def self.init_tests!(new_translations = nil)
				if Rails.env.test?
					if !@@testing_started
						@@testing_started = true
						File.open(@@translations_file, 'w+')
						File.open(@@translation_cache_file, 'w+')
					end
					if !new_translations.nil?
						record_translation(new_translations)
					end
				end
			end

			def needs_translation(key)
				@@needs_translation ||= Array.new
				@@needs_translation << key
			end

			def translate_control(translation)
				@@translationsOnThisPage = true
				datakeys = ''
				translation['vars'].each { |key, value| datakeys += ' data-var-' + key.to_s + '="' + value.to_s.gsub('"', '&quot;') + '"' }
				('<span class="translate-me ' + (translation['is_translated'] ? '' : 'un') + 'translated lang-' + (translation['lang']) + ' key--' + translation['key'].gsub('.', '--') + '" data-translate-key="' + translation['key'] + '" data-translate-untranslated="' + translation['untranslated'].gsub('"', '&quot;') + (translation['translated'] ? '" data-translate-translated="' + translation['translated'] : '') + '" data-vars="' + (translation['vars'].length ? translation['vars'].to_json.gsub('"', '&quot;') : '') + '" title="' + ('translate.alt_click') + '">' + (translation['html'] || translation['untranslated']) + '</span>').to_s.html_safe
			end

			def initialized?
				begin
					super
				rescue
					return false
				end
			end

			def initialize
				if !File.exist?(@@translation_cache_file)
					File.open(@@translation_cache_file, 'w+')
				end
				@@translation_cache = YAML.load(File.read(@@translation_cache_file)) || Hash.new
				super
			end

			def get_translation_info()
				begin
					YAML.load_file(@@translations_file) || {}
				rescue Exception => e
					# sometimes concurrency issues cause an exception during testing
					sleep(1/2.0)
					get_translation_info()
				end
			end

			def get_pluralization_rules(locale)
				rules = YAML.load_file(@@pluralization_rules_file)
				rules[locale.to_sym]
			end

			def get_language_codes()
				YAML.load_file(@@pluralization_rules_file).keys
			end

			def set_locale(host)
				@@hosts ||= Hash.new
				default = I18n.default_locale.to_s
				lang = @@hosts[host]
				if lang === false
					lang = nil
				elsif lang.nil?
					if (lang = host.gsub(/^(dev|test|www)[\-\.](.*)$/, '\2').gsub(/^(([^\.]+)\.)?[^\.]+\.[^\.]+$/, '\2')).blank?
						lang = default
					end
					if get_language_codes().include? lang
						if !language_enabled? lang
							I18n.locale = default
							return lang
						end
					else
						lang = nil
					end
				end
				I18n.locale = default unless lang.present?
				# return nil if the language doesn exist, false if it is not enabled, or the code if it is enabled
				lang.present? ? true : false
			end

			def get_language_completion(lang)
				total = 0
				complete = 0
				get_translation_info().each { |k,v|
					total += 1
					complete += v['languages'].include?(lang.to_s) ? 1 : 0
				}
				(total ? complete / total.to_f : 0.0) * 100.0
			end

			def language_enabled?(lang)
				lang.to_s == I18n.default_locale.to_s || get_language_completion(lang) > 66
			end

			def request_translation(key, vars, options)
				locale = options[:locale].to_s
				options[:locale] = :en
				translation = I18n.translate(key, vars, options)
				result = JSON.load(open("http://translate.google.com/translate_a/t?client=t&text=#{URI::escape(translation)}&hl=en&sl=en&tl=#{locale}&ie=UTF-8&oe=UTF-8&multires=1&otf=1&ssel=3&tsel=3&sc=1").read().gsub(/,+/, ',').gsub(/\[,+/, '[').gsub(/,+\]/, ']'))
				while result.is_a?(Array)
					result = result[0]
				end
				return result
			end

			def record_translation(key)
				translations = get_translation_info()
				translations ||= Hash.new

				if key.is_a(Array)
					key.each { |k| translations[k.to_s] ||= Hash.new }
				else
					translations[key.to_s] ||= Hash.new
				end
				File.open(@@translations_file, 'w') { |f| f.write translations.to_yaml }
			end

			protected
				def lookup(locale, key, scope = [], options = {})
					result = nil

					if key.is_a?(String)
						key = key.gsub(/(^\[|\])/, '').gsub(/\[/, '.')
					end

					if @@translation_cache && @@translation_cache.has_key?(locale.to_s) && @@translation_cache[locale.to_s].has_key?(key.to_s)
						result = @@translation_cache[locale.to_s][key.to_s]
					end
					if !result
						result = super(locale, key, scope, options)

						if Rails.env.test? && options[:behavior].to_s != 'scrict'
							if result
								@@translation_cache[locale.to_s] ||= Hash.new
								@@translation_cache[locale.to_s][key.to_s] = result
								File.open(@@translation_cache_file, 'w') { |f| f.write @@translation_cache.to_yaml }
							end

							translations = get_translation_info()
							translations ||= Hash.new
							translations[key.to_s] ||= Hash.new
							translations[key.to_s]['languages'] ||= Array.new
							translations[key.to_s]['pages'] ||= Array.new
							if options['behavior']
								translations[key.to_s]['behavior'] ||= options['behavior']
							end
							vars = []
							options.each { |o,v|
								if !I18n::RESERVED_KEYS.include?(o.to_sym) && o.to_s != 'behavior' && o.to_s != 'behavior_size'
									vars << o.to_sym
								end
							}
							if vars.size() > 0
								translations[key.to_s]['vars'] = vars
							end
							unless translations[key.to_s].has_key?('data')
								translations[key.to_s]['data'] = Array.new
								DevTranslation.where("key = '#{key.to_s}' OR key LIKE '#{key.to_s}#{I18n::Backend::Flatten::FLATTEN_SEPARATOR}%'").each { |t|
									translations[key.to_s]['data'] << ActiveSupport::JSON.encode(t.becomes(Translation))
									unless translations[key.to_s]['languages'].include?(t.locale.to_s)
										translations[key.to_s]['languages'] << t.locale.to_s
									end
								}
							end
							path = $page_info[:path]
							route = nil
							Rails.application.routes.routes.each { |r|
								if !route && r.path.match(path)
									route = r.path.spec.to_s.gsub(/\s*\(\.:\w+\)\s*$/, '')
								end
							}
							unless translations[key.to_s]['pages'].include?(route)
								translations[key.to_s]['pages'] << route
							end
							File.open(@@translations_file, 'w') { |f| f.write translations.to_yaml }
						end
					end

					result
				end
		end
	end
end

I18n.exception_handler = I18n::MissingTranslationExceptionHandler.new
