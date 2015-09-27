require 'redcarpet'

module ApplicationHelper
	include ScheduleHelper

	@@keyQueue = nil
	@@translationsOnThisPage = nil
	@@lastTranslation = nil
	@@allTranslations = nil
	@@no_banner = true
	@@banner_attribution_details = nil
	@@banner_image = nil
	@@has_content = true
	@@front_page = false
	@@body_class = nil
	@@test_location = nil

	def init_vars
		@@keyQueue = nil
		@@no_banner = true
		@@banner_attribution_details = nil
		@@banner_image = nil
		@@has_content = true
		@@front_page = false
		@@body_class = nil
	end

	def this_is_the_front_page
		@@front_page = true
	end

	def header_is_fixed
		@fixed_header = true
	end

	def is_header_fixed?
		@fixed_header ||= false
	end

	def is_this_the_front_page?
		return @@front_page
	end

	def header_classes
		classes = Array.new
		classes << 'fixed' if is_header_fixed?
		return classes
	end

	def ThereAreTranslationsOnThisPage?
		@@translationsOnThisPage
	end

	def get_all_translations
		@@allTranslations
	end

	def title(page_title)
		content_for(:title) { page_title.to_s }
	end

	def description(page_description)
		content_for(:description) { page_description.to_s }
	end

	def banner_image(banner_image, name: nil, id: nil, user_id: nil, src: nil)
		@@no_banner = false
		@@banner_image = banner_image
		if (name || id || user_id || src)
			@@banner_attribution_details = {:name => name, :id => id, :user_id => user_id, :src => src}
		end
		content_for(:banner_image) { banner_image.to_s }
	end

	def banner_attrs(banner_image)
		@@no_banner = false
		if banner_image.length > 0
			@@banner_image = banner_image
			return {style: 'background-image: url(' + banner_image + ');', class: 'has-image' }
		end
		{class: 'no-image'}
	end

	def has_banner?
		!@@no_banner
	end

	def has_content?
		@@has_content
	end

	def has_no_content
		@@has_content = false
	end

	def banner_title(banner_title)
		@@no_banner = false
		content_for(:banner) { ('<div class="row"><h1>' + banner_title.to_s + '</h1></div>').html_safe }
	end

	def banner_attribution
		if @@banner_image && @@banner_attribution_details
			src = @@banner_attribution_details[:src]
			attribution = '<div class="photo-attribution' + (src ? ' ' + src : '') + '">'
			if src == 'panoramio'
				attribution += '<a href="http://www.panoramio.com/photo/' + @@banner_attribution_details[:id].to_s + '" target="_blank">&copy; ' +
						_('Banner_image_provided_by_panoramio_user') +
					'</a> <a href="http://www.panoramio.com/user/' + @@banner_attribution_details[:user_id].to_s + '" target="_blank">' + @@banner_attribution_details[:name] + '</a>' +
					'<span>' + _('Photos_provided_by_Panoramio_are_under_the_copyright_of_their_owners')  + '</span>'
			end
			attribution += '</div>'
			attribution.html_safe
		end
	end

	def dom_ready(&block)
		content_for(:dom_ready, &block)
	end

	def body_class(c)
		@@body_class ||= Array.new
		@@body_class << (c.is_a?(Array) ? c.join(' ') : c)
	end

	def page_style#(style)
		#classes = ['page-style-' + style.to_s]
		classes = Array.new

		classes << 'has-translations' if ThereAreTranslationsOnThisPage?
		classes << 'no-content' unless @@has_content
		classes << 'has-banner-image' if @@banner_image
		classes << @@body_class.join(' ') if @@body_class
		classes << 'fixed-banner' if is_header_fixed?

		if params[:controller]
			if params[:controller] == 'application'
				if params[:action]
					classes << params[:action]
				end
			else
				classes << params[:controller] 

				if params[:action]
					classes << params[:controller] + '-' + params[:action]
				end
			end
		end
		return classes
	end

	def yield_or_default(section, default = '')
		content_for?(section) ? content_for(section) : default
	end

#	def _(key, behavior = nil, behavior_size = nil, locale: nil, vars: {}, html: nil, blockData: {}, &block)
#		options = vars
#		options[:fallback] = true
#		if behavior
#			options[:behavior] = behavior
#			options[:behavior_size] = behavior_size
#		end
#		if locale
#			options[:locale] = locale.to_sym
#		end
#		#if vars
#		#	puts "\nVARS:\t#{vars}\n"
#		#end
#		I18n.translate(key, options)
#
#		#queued_keys = nil
#		#result = nil
#
#		#if key.kind_of?(Hash)
#		#	blockData.merge!(key)
#		#	key = key.keys
#		#end
#
#		#if block_given?
#		#	@@keyQueue ||= Array.new
#
#		#	if key.kind_of?(Array)
#		#		@@keyQueue += key
#		#	else
#		#		@@keyQueue << key
#		#	end
#		#end
#
#		#if key.kind_of?(Array)
#		#	new_key = key.shift
#		#	if key.count > 0
#		#		queued_keys = key.dup
#		#	end
#		#	key = new_key
#		#end
#
#		#if blockData[key]
#		#	behavior = blockData[key][:behavior] || nil
#		#	behavior_size = blockData[key][:behavior_size] || nil
#		#	vars = blockData[key][:vars] || {}
#		#end
#
#		#@@lastTranslation = nil
#		#generate_control = _can_translate?
#
#		#puts "\nLLOOCCAALLEE:\t#{locale.to_s}"
#		#translation = _do_translate(key, vars, behavior, behavior_size, locale)
#
#		#if block_given?
#		#	html = capture(&block)
#		#end
#
#		#if html
#		#	translation['html'] = html.gsub('%' + key + '%', translation['untranslated'])
#		#end
#
#		#if generate_control
#		#	@@lastTranslation = translation
#		#	@@allTranslations ||= Hash.new
#		#	@@allTranslations[key] = key
#
#		#	result = _translate_me(translation)
#		#end
#
#		#result ||= translation['html'] || (behavior.to_s == 'strict' ? nil : translation['untranslated'])
#
#		#if queued_keys
#		#	return _ queued_keys, behavior, behavior_size, vars: vars, html: result, blockData: blockData
#		#end
#
		#return result
#	end

	def _translate_me(translation)
		@@translationsOnThisPage = true
		datakeys = ''
		translation['vars'].each { |key, value| datakeys += ' data-var-' + key.to_s + '="' + value.to_s.gsub('"', '&quot;') + '"' }
		('<span class="translate-me ' + (translation['is_translated'] ? '' : 'un') + 'translated lang-' + (translation['lang']) + ' key--' + translation['key'].gsub('.', '--') + '" data-translate-key="' + translation['key'] + '" data-translate-untranslated="' + translation['untranslated'].gsub('"', '&quot;') + (translation['translated'] ? '" data-translate-translated="' + translation['translated'] : '') + '" data-vars="' + (translation['vars'].length ? translation['vars'].to_json.gsub('"', '&quot;') : '') + '" title="' + ('translate.alt_click') + '">' + (translation['html'] || translation['untranslated']) + '</span>').to_s.html_safe
	end

	def _do_translate(key, vars, behavior, behavior_size, locale)
		translation = {'key' => key, 'lang' => '0', 'vars' => vars}
		v = vars.dup
		begin
			v[:raise] = true
			options = {:raise => true}
			if locale
				options[:locale] = locale.to_sym
			end
			translation['untranslated'] = I18n.translate(key, v, options)
			translation['lang'] = locale.to_s
			translation['is_translated'] = true

			hash = Hash.new
			translations = Translation.where(["locale = ? AND key LIKE ?", locale.to_s, key + '%']).take(6).each { |o| hash[o.key] = o.value }
			translation['translated'] = hash.to_json.gsub('"', '&quot;')
		rescue I18n::MissingTranslationData
			default_translation = I18n::MissingTranslationExceptionHandler.note(key, behavior, behavior_size)
			translation['untranslated'] = default_translation
		end
		return translation
	end

	def _can_translate?()
		false
	end

	#def _!()
	#	if @@keyQueue
	#		return '%' + @@keyQueue.shift + '%'
	#	end
	#end

	#def _?()
	#	if @@keyQueue
	#		return '%' + @@keyQueue[0] + '%'
	#	end
	#end

	def sortable(objects, id = 'id', url: nil, &block)
		result = '<ul class="sortable sortable-' + objects[0].class.name.underscore.gsub('_', '-') + (url ? ('" data-url="' + url) : '') + '" data-id="' + id + '">'
		objects.each_index do |i|
			@this = objects[i]
			result += '<li class="sortable-item">'
			result += hidden_field_tag (id + "[#{i}]"), objects[i][id]
			result += hidden_field_tag ('position' + "[#{i}]"), i, :class => 'sortable-position'
			if block_given?
				result += capture(objects[i], &block)
			end
			result += '</li>'
		end
		result += '</div>'
		result.html_safe
	end

	def tabs object, tabs
		type = object.class.name.downcase
		tab_list = ''

		tabs.each do |tab|
			link = nil
			if self.respond_to?(type + '_' + tab.to_s + '_path')
				link = self.send(type + '_' + tab.to_s + '_path', object)
			elsif self.respond_to?(tab.to_s + '_' + type + '_path')
				link = self.send(tab.to_s + '_' + type + '_path', object)
			end

			c = ['tab', 'tab-' + (link ? tab.to_s : 'show')]
			if params[:action] == tab.to_s
				c << 'current'
			end
			link_html = ''
			if tab.is_a?(Hash)
				func = tab.keys[0]
				val = tab[func]
				args = val ? (val.is_a?(Array) ? (val.collect { |v| object[v] } ) : [object[val]] ) : nil

				link_html = link_to func.to_s.gsub(/_path$/, ''), args ? self.send(func, args) : self.send(func), :class => c
			else
				#x
				#link_html = link_to tab, link || object, :class => c
			end
			tab_list += link_html
		end
		('<nav class="row centered">
			<div class="tabs">' +
				tab_list +
			'</div>
		</nav>').html_safe
	end

	def tabs!
		object = nil
		tabs = nil
		case params[:controller]
			when 'organizations'
				object = @organization
				tabs = OrganizationsHelper::TABS
			when 'conferences'
				object = @conference
				tabs = ConferencesHelper::TABS
			when 'workshops'
				object = [@conference, @workshop]
				tabs = WorkshopsHelper::TABS
		end

		if object && tabs
			return tabs object, tabs
		end
	end

	def sub_tabs object, tabs
		type = object.class.name.downcase
		tab_list = ''

		tabs.each do |tab|
			link = nil
			if self.respond_to?(type + '_' + tab.to_s + '_path')
				link = self.send(type + '_' + tab.to_s + '_path', object)
			elsif self.respond_to?(tab.to_s + '_' + type + '_path')
				link = self.send(tab.to_s + '_' + type + '_path', object)
			end

			c = ['sub-tab', 'sub-tab-' + (link ? tab.to_s : 'show')]
			if current_page?(link)
				c << 'current'
			end
			tab_list += link_to tab, link || object, :class => c
		end
		('<nav class="sub-tabs">' + tab_list + '</nav>').html_safe
	end

	def sub_tabs!
		object = nil
		tabs = nil
		case params[:controller]
			when 'organizations'
				object = @organization
				tabs = OrganizationsHelper::SUB_TABS
			when 'conferences'
				object = @conference
				tabs = ConferencesHelper::SUB_TABS
		end

		if object && tabs
			return sub_tabs object, tabs
		end
	end

	def m(*args)
		_(*args) { |t|
			markdown(t)
		}
	end

	def markdown(object, attribute = nil)
		return '' unless object
		content = attribute ? object.send(attribute.to_s) : object
		@markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML.new({
				filter_html: true,
				hard_wrap: true,
				space_after_headers: true,
				fenced_code_blocks: true,
				link_attributes: { target: "_blank" }
			}), {
				autolink: true,
				disable_indented_code_blocks: true,
				superscript: true
			})
		@markdown.render(content).html_safe
	end

	def paragraph(object, attribute = nil)
		return '' unless object
		content = attribute ? object.send(attribute.to_s) : object
		result = ''
		if content =~ /<(p|span|h\d|div)[^>]*>/
			result = content.gsub(/\s*(style|class|id|width|height|font)=\".*?\"/, '')
				.gsub(/&nbsp;/, ' ')
				.gsub(/<(\/)?\s*h\d\s*>/, '<\1h3>')
				.gsub(/<p>(.*?)<br\s\/?>\s*(<br\s\/?>)+/, '<p>\1</p><p>')
				.gsub(/<span[^>]*>\s*(.*?)\s*<\/span>/, '\1')
				.gsub(/<p>\s*<\/p>/, '')
				.gsub(/<(\/)?div>/, '<\1p>')
			if !(result =~ /<p[^>]*>/)
				result = '<p>' + result + '</p>'
			end
		else
			result = markdown(object, attribute)
		end
		result.html_safe
	end

	def form_field(f, response = nil)
		id = 'field_' + f.id.to_s
		html = p(f, 'title')

		options = JSON.parse(f.options)
		if f.field_type == 'multiple'
			if f.help
				html += ('<div class="help">' + p(f, 'help') + '</div>').html_safe
			end

			opts = Hash.new
			options['options'].split(/\s*\n\s*/).each do |value|
				kv = value.split(/\s*\|\s*/, 2)
				opts[kv[0]] = kv[1]
			end

			val = response ? ActiveSupport::JSON.decode(response.data) : Hash.new

			if f.repeats?
				is_array = f.is_array?
				opts.each do |key, value|
					n = (id + (is_array ? ('_' + key) : '')).to_sym
					v = is_array ? (val ? val[key] : nil) : key
					o = {:label => value}
					if f.required
						options[:required] = true
					end
					html += _form_field(options['selection_type'], n, v, o)
				end
			else
				html += _form_field(options['selection_type'], id.to_sym, options_for_select(opts.invert, val), {})
			end
		else
			#html += field(id.to_sym, options['input_type'] + '_tag', label: false, placeholder: f.help, value: response ? ActiveSupport::JSON.decode(response.data) : nil, required: f.required)
			opts = {label: false, placeholder: f.help && f.help.length > 0 ? f.help : false}
			if f.required
				opts[:required] = true
			end
			html += _form_field(options['input_type'], id.to_sym, response ? ActiveSupport::JSON.decode(response.data) : nil, opts)
		end

		html.html_safe
	end

	def t(*a)
		_(*a)
	end

	def lookup_ip
		if request.remote_ip == '127.0.0.1' || request.remote_ip == '::1'
			session['remote_ip'] || (session['remote_ip'] = open("http://checkip.dyndns.org").first.gsub(/^.*\s([\d\.]+).*$/s, '\1').gsub(/[^\.\d]/, ''))
		else
			request.remote_ip
		end
	end

	def get_remote_location
		Geocoder.search(session['remote_ip'] || (session['remote_ip'] = open("http://checkip.dyndns.org").first.gsub(/^.*\s([\d\.]+).*$/s, '\1').gsub(/[^\.\d]/, ''))).first
	end

	def lookup_ip_location
		begin
			if is_test? && ApplicationController::get_location.present?
				Geocoder.search(ApplicationController::get_location).first
			elsif request.remote_ip == '127.0.0.1' || request.remote_ip == '::1'
				get_remote_location
			else
				request.location || get_remote_location
			end
		rescue
			nil
		end
	end

	def hash_to_html_attributes(hash, prefix = '')
		attributes = ''
		if hash
			hash.each { |k,v|
				k = k.to_s
				if v
					if v.is_a?(Hash)
						attributes += hash_to_html_attributes(v, 'data-')
					else
						attributes += " #{k}=\"" + (v.is_a?(Array) ? v.join(' ') : v) + '"'
					end
				end
			}
		end
		attributes
	end

	def icon(id, attributes = nil)
		('<svg' + hash_to_html_attributes(attributes) + '><use xlink:href="/assets/icons.svg#bb-icon-' + id + '"></use></svg>').html_safe
	end

	def static_map(location, zoom, width, height)
		require 'fileutils'
		local_file_name = "#{location}-#{width}x#{height}z#{zoom}.png"
		file = File.join("public", "maps/#{local_file_name}")
		FileUtils.mkdir_p("public/maps") unless File.directory?("public/maps")
		if !File.exist?(file)
			url = "https://maps.googleapis.com/maps/api/staticmap?center=#{location}&zoom=#{zoom}&size=#{width}x#{height}&maptype=roadmap&markers=size:small%7C#{location}&key=AIzaSyAH7U8xUUb8IwDPy1wWuYGprzxf4E1Jj4o"
			require 'open-uri'
			open(file, 'wb') do |f|
				f << open(url).read
			end
		end

		cdn("/maps/#{local_file_name}")
	end

	def cdn(file)
		(Rails.application.config.action_controller.asset_host || '') + file
	end

	def is_production?
		Rails.env == 'production' || Rails.env == 'preview'
	end

	def is_test?
		Rails.env == 'test'
	end

	def subdomain
		request.env['SERVER_NAME'].gsub(/^(\w+)\..*$/, '\1')
	end

	def is_test_server?
		subdomain == 'test'
	end

	#def location(location)
	#	territory = Carmen::Country.coded(location.country).subregions.coded(location.territory)
	#	location.city + (territory ? ' ' + territory.name : '') + ', ' + Carmen::Country.coded(location.country).name
	#end

	def rand_hash(length = 16, model = nil, field = nil)
		if field
			hash = rand_hash(length)
			while !model.to_s.to_s.singularize.classify.constantize.find_by(field => hash).nil?
				hash = rand_hash(length)
			end
		end
		rand(36**length).to_s(36)
	end

	def get_panoramio_image(location)
		if is_test?
			params[:image] = 'panoramio.jpg'
			params[:attribution_id] = 1234
			params[:attribution_user_id] = 5678
			params[:attribution_name] = 'Some Guy'
			params[:attribution_src] = 'panoramio'
			return params
		end

		location = location.city + ', ' + (location.territory ? location.territory + ' ' : '') + location.country
		$panoramios ||= Hash.new
		$panoramios[location] ||= 0
		$panoramios[location] += 1
		result = Geocoder.search(location).first
		if result
			points = Geocoder::Calculations.bounding_box([result.latitude, result.longitude], 5, { :unit => :km })
			options = {:set => :public, :size => :original, :from => 0, :to => 20, :mapfilter => false, :miny => points[0], :minx => points[1], :maxy => points[2], :maxx => points[3]}
			url = 'http://www.panoramio.com/map/get_panoramas.php?' + options.to_query
			response = JSON.parse(open(url).read)
			response['photos'].each { |img|
				if img['width'].to_i > 980
					if Organization.find_by(:cover_attribution_id => img['photo_id'], :cover_attribution_src => 'panoramio').nil? && Conference.find_by(:cover_attribution_id => img['photo_id'], :cover_attribution_src => 'panoramio').nil?
						params[:image] = img['photo_file_url']
						params[:attribution_id] = img['photo_id']
						params[:attribution_user_id] = img['owner_id']
						params[:attribution_name] = img['owner_name']
						params[:attribution_src] = 'panoramio'
						return params
					end
				end
			}
		end
		return nil
	end

	def get_secure_info(name)
		YAML.load(File.read(Rails.root.join("config/#{name.to_s}.yml")))[Rails.env].symbolize_keys
	end

	def location(location)
		return nil if location.blank?

		city = nil
		region = nil
		country = nil
		if location.is_a?(Location)
			country = location.country
			region = location.territory
			city = location.city
		else
			country = location.data['country_code']
			region = location.data['region_code']
			city = location.data['city']
		end
		l = Array.new
		l << (_!city)
		l << I18n.t("geography.subregions.#{country}.#{region}") if region.present?
		l << I18n.t("geography.countries.#{country}") if !(country =~ /^(US|CA)$/)
		l.join(_!', ')
	end

	def nav_link(link, title)
		link_to "<span>#{title}</span>".html_safe, link, :class => (current_page?(link) ? 'current' : nil)
	end

	def date(date, format = :long)
		I18n.l(date, :format => format) # default, long, short
	end

	def date_span(date1, date2)
		key = 'same_month'
		if date1.year != date2.year
			key = 'different_year'
		elsif date1.month != date2.month
			key = 'same_year'
		end
		d1 = I18n.l(date1.to_date, format: "span_#{key}_date_1".to_sym)
		d2 = I18n.l(date2.to_date, format: "span_#{key}_date_2".to_sym)
		I18n.t('date.date_span', {:date_1 => d1, :date_2 => d2})
	end

	def generate_confirmation(user, url, expiry = nil)
		ApplicationController::generate_confirmation(user, url, expiry)
	end

	def money(amount)
		return _!('$0.00') if amount == 0
		_!((amount * 100).to_i.to_s.gsub(/^(.*)(\d\d)$/, '$\1.\2'))
	end

	def percent(p)
		return _!('0.00%') if p == 0
		_!((p * 10000).to_i.to_s.gsub(/^(.*)(\d\d)$/, '\1.\2%'))
	end

	private
		def _form_field(type, name, value, options)
			if type == 'check_box'
				self.send(type + '_tag', name, "1", value, options)
			else
				self.send(type + '_tag', name, value, options)
			end
		end
end
