require 'i18n/backend/active_record'
require 'yaml'

class DevTranslation < Translation
	self.table_name = 'translations'
	establish_connection :development
end

module I18n
	class MissingTranslationExceptionHandler < ExceptionHandler
		def self.lorem_ipsum(method, size)
			options = {:random => true}
			case method.to_s
			when 'c', 'char', 'character', 'characters'
				if size
					return Forgery::LoremIpsum.characters size, options
				end
				return Forgery::LoremIpsum.character, options
			when 'w', 'word', 'words'
				if size
					return Forgery::LoremIpsum.words size, options
				end
				#return'LOREM'
				return Forgery::LoremIpsum.word options
			when 's', 'sentence', 'sentences'
				if size
					return Forgery::LoremIpsum.sentences size, options
				end
				return Forgery::LoremIpsum.sentence options
			when 'p', 'paragraph', 'paragraphs'
				if size
					return Forgery::LoremIpsum.paragraphs size, options.merge({:sentences => 10})
				end
				return Forgery::LoremIpsum.sentences 10, options
			when 't', 'title'
				return Forgery::LoremIpsum.sentences 1, options
			end
			return nil
		end

		def self.note(key, behavior = nil, behavior_size = nil)
			I18n.backend.needs_translation(key)
			if behavior
				return self.lorem_ipsum(behavior, behavior_size)
			end
			key.to_s.gsub(/^world\..*\.(.+)\.name$/, '\1').gsub(/^.*\.(.+)?$/, '\1').gsub('_', ' ')
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

			@@translations_file = 'config/locales/.translations.yml'
			@@translation_cache_file = 'config/locales/.translation-cache.yml'
			@@translation_cache

			def needs_translation(key)
				@@needs_translation ||= Array.new
				@@needs_translation << key
			end

			def initialized?
				begin
					super
				rescue
					return false
				end
			end

			def initialize
				if Rails.env.test?
					File.open(@@translations_file, 'w+')
					File.open(@@translation_cache_file, 'w+')
				end
				@@translation_cache = YAML.load(File.read(@@translation_cache_file)) || Hash.new
				super
			end

			protected
				def lookup(locale, key, scope = [], options = {})
					result = nil
					if @@translation_cache && @@translation_cache.has_key?(locale.to_s) && @@translation_cache[locale.to_s].has_key?(key.to_s)
						result = @@translation_cache[locale.to_s][key.to_s]
					end
					if !result
						result = super(locale, key, scope, options)

						if Rails.env.test?
							if result
								@@translation_cache[locale.to_s] ||= Hash.new
								@@translation_cache[locale.to_s][key.to_s] = result
								File.open(@@translation_cache_file, 'w') { |f| f.write @@translation_cache.to_yaml }
							end

							translations = YAML.load_file(@@translations_file)
							translations ||= Hash.new
							translations[key.to_s] ||= Hash.new
							translations[key.to_s]['langauges'] ||= Hash.new
							if result != nil
								translations[key.to_s]['langauges'][locale.to_s] = result
							end
							translations[key.to_s]['pages'] ||= Array.new
							unless translations[key.to_s].has_key?('data')
								translations[key.to_s]['data'] = Array.new
								DevTranslation.where("key = '#{key.to_s}' OR key LIKE '#{key.to_s}#{I18n::Backend::Flatten::FLATTEN_SEPARATOR}%'").each { |t|
									translations[key.to_s]['data'] << t.becomes(Translation)
								}
							end
							path = $page_info[:path]
							unless translations[key.to_s]['pages'].include?(path)
								translations[key.to_s]['pages'] << path
							end
							File.open(@@translations_file, 'w') { |f| f.write translations.to_yaml }
						end
					end

					if Rails.env.test?
					end

					result
				end
		end
	end
end

I18n.exception_handler = I18n::MissingTranslationExceptionHandler.new
