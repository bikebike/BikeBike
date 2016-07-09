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

	def add_stylesheet(sheet)
		@stylesheets ||= []
		@stylesheets << sheet unless @stylesheets.include?(sheet)
	end

	def stylesheets
		html = ''
		Rack::MiniProfiler.step('inject_css') do
			html += inject_css!
		end
		(@stylesheets || []).each do |css|
			Rack::MiniProfiler.step("inject_css #{css}") do
				html += inject_css! css.to_s
			end
		end
		html += stylesheet_link_tag 'i18n-debug' if request.params['i18nDebug']
		return html.html_safe
	end

	def add_inline_script(script)
		@_inline_scripts ||= []
		script = Rails.application.assets.find_asset("#{script.to_s}.js").to_s
		@_inline_scripts << script unless @_inline_scripts.include?(script)
	end

	def inline_scripts
		return '' unless @_inline_scripts.present?
		"<script>#{@_inline_scripts.join("\n")}</script>".html_safe
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

	def page_style
		classes = Array.new

		classes << 'has-translations' if ThereAreTranslationsOnThisPage?
		classes << 'no-content' unless @@has_content
		classes << 'has-banner-image' if @@banner_image
		classes << @@body_class.join(' ') if @@body_class
		classes << 'fixed-banner' if is_header_fixed?

		if params[:controller]
			classes << params[:action]
			unless params[:controller] == 'application'
				classes << params[:controller] 

				if params[:action]
					classes << "#{params[:controller]}-#{params[:action]}"
				end
			end
		end
		return classes
	end

	def yield_or_default(section, default = '')
		content_for?(section) ? content_for(section) : default
	end

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

	def off_screen(text, id = nil)
		content_tag(:span, text.html_safe, id: id, class: 'screen-reader-text')
	end

	def url_for_locale(locale)
		new_params = params.merge({action: (params[:_original_action] || params[:action])})
		new_params.delete(:_original_action)
		
		return url_for(new_params.merge({lang: locale.to_s})) if Rails.env.development? || Rails.env.test?
		return "https://preview-#{locale.to_s}.bikebike.org#{url_for(new_params)}" if Rails.env.preview?
		"https://#{locale.to_s}.bikebike.org#{url_for(new_params)}"
	end

	def registration_steps(conference = @conference)
		{
			pre: [:policy, :basic_info, :workshops],
			open: [:policy, :basic_info, :questions, :payment, :workshops]
		}[@this_conference.registration_status]
	end

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
		elsif location.data.present? && location.data['address_components'].present?
			component_map = {
				'locality' => :city,
				'administrative_area_level_1' => :region,
				'country' => :country
			}
			location.data['address_components'].each do | component |
				types = component['types']
				country = component['short_name'] if types.include? 'country'
				region = component['short_name'] if types.include? 'administrative_area_level_1'
				city = component['long_name'] if types.include? 'locality'
			end
		else
			country = location.data['country_code']
			region = location.data['region_code']
			city = location.data['city']
		end

		# we need cities for our logic, don't let this continue if we don't have one
		return nil unless city.present?

		hash = Hash.new
		hash[:city] = _!(city) unless city.blank?
		hash[:region] = _("geography.subregions.#{country}.#{region}") unless region.blank? || country.blank?
		hash[:country] = _("geography.countries.#{country}") unless country.blank?

		# return the formatted location or the first value if we only have one value
		return hash.length > 1 ? _("geography.formats.#{hash.keys.join('_')}", vars: hash) : hash.values.first
	end

	def same_city?(location1, location2)
		return false unless location1.present? && location2.present?

		location1 = location(location1) unless location1.is_a?(String)
		location2 = location(location2) unless location2.is_a?(String)

		location1.eql? location2
	end

	def show_errors(field, value)
		return '' unless @errors && @errors[field].present?

		error_txt = _"errors.messages.fields.#{field.to_s}.#{@errors[field]}", :s, vars: { value: value }
		
		"<div class=\"field-error\">#{error_txt}</div>".html_safe
	end

	def nav_link(link, title = nil, class_name = nil)
		if title.nil? && link.is_a?(Symbol)
			title = link
			link = send("#{link.to_s}_path")
		end
		if class_name.nil? && title.is_a?(Symbol)
			class_name = title
		end
		title = _"page_titles.#{title.to_s.titlecase.gsub(/\s/, '_')}"
		classes = []
		classes << class_name if class_name.present?
		classes << "strlen-#{strip_tags(title).length}"
		classes << 'current' if request.fullpath.start_with?(link.gsub(/^(.*?)\/$/, '\1'))
		link_to "<span class=\"title\">#{title}</span>".html_safe, link, :class => classes
	end

	def language(locale, original_language = false)
		args = {}
		args[:locale] = locale if original_language
		_("languages.#{locale}", args)
	end

	def date(date, format = :long)
		I18n.l(date.is_a?(String) ? Date.parse(date) : date, :format => format)
	end

	def time(time, format = :short)
		if time.is_a?(String)
			time = Date.parse(time)
		elsif time.is_a?(Float) || time.is_a?(Integer)
			time = DateTime.now.midnight + time.hours
		end
				
		I18n.l(time, :format => format)
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
		_('date.date_span', vars: {:date_1 => d1, :date_2 => d2})
	end

	def time_length(length)
		hours = length.to_i
		minutes = ((length - hours) * 60).to_i
		hours = hours > 0 ? (I18n.t 'datetime.distance_in_words.x_hours', count: hours) : nil
		minutes = minutes > 0 ? (I18n.t 'datetime.distance_in_words.x_minutes', count: minutes) : nil
		return hours.present? ? (minutes.present? ? (I18n.t 'datetime.distance_in_words.x_and_y', x: hours, y: minutes) : hours) : minutes
	end

	def hour_span(time1, time2)
		(time2 - time1) / 3600
	end

	def hours(time1, time2)
		time_length hour_span(time1, time2)
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

	def data_set(header_type, header_key, attributes = {}, &block)
		raw_data_set(header_type, _(header_key), attributes, &block)
	end

	def raw_data_set(header_type, header, attributes = {}, &block)
		attributes[:class] = attributes[:class].split(' ') if attributes[:class].is_a?(String)
		attributes[:class] = [attributes[:class].to_s] if attributes[:class].is_a?(Symbol)
		attributes[:class] ||= []
		attributes[:class] << 'data-set'
		content_tag(:div, attributes) do
			content_tag(header_type, header, class: 'data-set-key') +
			content_tag(:div, class: 'data-set-value', &block)
		end
	end

	def conference_days_options(conference = nil)
		conference ||= @this_conference || @conference
		return [] unless conference

		dates = []
		day = conference.start_date - 7.days
		last_day = conference.end_date + 7.days

		while day <= last_day
			dates << day
			day += 1.day
		end

		return dates
	end

	def conference_days_options_list(period, conference = nil, format = nil)
		conference ||= @this_conference || @conference
		return [] unless conference

		days = []

		conference_days_options(conference).each do |day|
			belongs_to_periods = []
			belongs_to_periods << :before if day <= conference.start_date
			belongs_to_periods << :after if day >= conference.end_date
			belongs_to_periods << :during if day >= conference.start_date && day <= conference.end_date
			days << [date(day.to_date, format || :span_same_year_date_1), day] if belongs_to_periods.include?(period)
		end
		return days
	end

	def day_select(value = nil, args = {})
		selectfield :day, value, conference_days_options_list(:during, nil, args[:format]), args
	end

	def time_select(value = nil, args = {}, start_time = 8, end_time = 23.5, step = 0.5)
		time = start_time
		times = []
		while time <= end_time
			times << [time(DateTime.now.midnight + time.hours), time]
			time += step
		end
		selectfield :time, value, times, args
	end

	def length_select(value = nil, args = {}, min_length = 0.5, max_length = 6, step = 0.5)
		length = min_length
		lengths = []
		while length <= max_length
			lengths << [time_length(length), length]
			length += step
		end
		selectfield :time_span, value, lengths, args
	end

	def block_select(value = nil, args = {})
		blocks = {}
		@workshop_blocks.each_with_index do | info, block |
			info['days'].each do | day |
				blocks[(day.to_i * 10) + block] = [ "#{(I18n.t 'date.day_names')[day.to_i]} Block #{block + 1}", "#{day}:#{block}" ]
			end
		end
		selectfield :workshop_block, value, blocks.sort.to_h.values, args
	end

	def location_select(value = nil, args = {})
		locations = []
		if @this_conference.event_locations.present?
			@this_conference.event_locations.each do | location |
				locations << [ location.title, location.id ]
			end
		end
		selectfield :event_location, value, locations, args
	end

	def location_name(id)
		location = EventLocation.find(id)
		return '' unless location.present?
		return location.title
	end

	def host_options_list(hosts)
		options = [[nil, nil]]
		hosts.each do | id, registration |
			options << [registration.user.name, id]
		end
		return options
	end

	def registration_step_menu
		steps = current_registration_steps(@registration)
		return '' unless steps.present?

		pre_registration_steps = ''
		post_registration_steps = ''
		post_registration = false

		steps.each do | step |
			text = _"articles.conference_registration.headings.#{step[:name].to_s}"
			h = content_tag :li, class: [step[:enabled] ? :enabled : nil, @register_template == step[:name] ? :current : nil] do
				if step[:enabled]
					content_tag :div, (link_to text, register_step_path(@this_conference.slug, step[:name])).html_safe, class: :step
				else
					content_tag :div, text, class: :step
				end
			end

			if step[:name] == :workshops
				post_registration = true
			end

			if post_registration
				post_registration_steps += h.html_safe
			else
				pre_registration_steps += h.html_safe
			end
		end

		html = (
			row class: 'flow-steps' do
				columns do
					(content_tag :ul, id: 'registration-steps' do
						pre_registration_steps.html_safe
					end).html_safe + 
					(content_tag :ul, id: 'post-registration-steps' do
						post_registration_steps.html_safe
					end).html_safe
				end
			end
		)

		return html.html_safe
	end

	def broadcast_methods
		[
			:registered,
			:confirmed_registrations,
			:unconfirmed_registrations,
			:unconfirmed_registrations,
			:workshop_facilitators,
			:everyone,
		]
	end

	def admin_steps
		[:edit, :stats, :broadcast, :housing, :locations, :meals, :events, :workshop_times, :schedule]
	end

	def valid_admin_steps
		admin_steps + [:broadcast_sent]
	end

	def admin_menu
		steps = ''
		admin_steps.each do | step |
			steps += content_tag(:li, class: (step.to_s == @admin_step ? :current : nil)) do
				link_to _("menu.submenu.admin.#{step.to_s.titlecase}"), step == :edit ?
					register_step_path(@this_conference.slug, :administration) :
					administration_step_path(@this_conference.slug, step.to_s)
			end
		end
		content_tag :ul, steps.html_safe, id: 'registration-admin-menu'
	end

	def interest_button(workshop)
		interested = workshop.interested?(current_user) ? :remove_interest : :show_interest
		id = "#{interested.to_s.gsub('_', '-')}-#{workshop.id}"
		return (off_screen (_"forms.actions.aria.#{interested.to_s}"), id) + 
			(button_tag interested, :value => :toggle_interest, :class => (workshop.interested?(current_user) ? :delete : :add), aria: { labelledby: id })
	end

	def host_guests_widget(registration)
		html = ''
		classes = ['host']

		id = registration.id
		@housing_data[id][:guests].each do | area, guests |
			max_space = @housing_data[id][:space][area] || 0
			area_name = (_"forms.labels.generic.#{area}")
			status_html = ''
			if @housing_data[id][:warnings].present? && @housing_data[id][:warnings][:space].present? && @housing_data[id][:warnings][:space][area].present?
				@housing_data[id][:warnings][:space][area].each do | w |
					status_html += content_tag(:div, _("warnings.housing.space.#{w.to_s}"), class: 'warning')
				end
			end
			space_html = content_tag(:h5, area_name + _!(" (#{guests.size.to_s}/#{max_space.to_s})") + status_html.html_safe)
			guest_items = ''
			guests.each do | guest_id, guest |
				guest_items += content_tag(:li, guest[:guest].user.name, id: "hosted-guest-#{guest_id}")
			end
			space_html += content_tag(:ul, guest_items.html_safe)
			space_html += button_tag :place_guest, type: :button, value: "#{area}:#{id}", class: [:small, 'place-guest', 'on-top-only', guests.size >= max_space ? (guests.size > max_space ? :overbooked : :booked) : nil, max_space > 0 ? nil : :unwanted] 
			html += content_tag(:div, space_html, class: [:space, area, max_space > 0 || guests.size > 0 ? nil : 'on-top-only'])
		end

		classes << 'status-warning' if @housing_data[id][:warnings].present?
		classes << 'status-error' if @housing_data[id][:errors].present?
		
		return { html: html.html_safe, class: classes.join(' ') }
	end

	def signin_link
		@login_dlg ||= true
		link_to (_'forms.actions.generic.login'), settings_path, data: { 'sign-in': true }
	end

	def link_with_confirmation(link_text, confirmation_text, path, args = {})
		@confirmation_dlg ||= true
		args[:data] ||= {}
		args[:data][:confirmation] = true
		link_to path, args do
			(link_text.to_s + content_tag(:template, confirmation_text, class: 'message')).html_safe
		end
	end

	def link_info_dlg(link_text, info_text, info_title, args = {})
		@info_dlg ||= true
		args[:data] ||= {}
		args[:data]['info-title'] = info_title
		args[:data]['info-text'] = true
		content_tag(:a, args) do
			(link_text.to_s + content_tag(:template, info_text, class: 'message')).html_safe
		end
	end

	def button_with_confirmation(button_name, confirmation_text, args = {})
		@confirmation_dlg ||= true
		args[:data] ||= {}
		args[:data][:confirmation] = true
		button_tag args do
			(button_name.to_s + content_tag(:template, confirmation_text, class: 'message')).html_safe
		end
	end

	def richtext(text, reduce_headings = 2)
		return '' unless text.present?
		return _!(text).
			gsub(/<(\/?)h4>/, '<\1h' + (reduce_headings + 4).to_s + '>').
			gsub(/<(\/?)h3>/, '<\1h' + (reduce_headings + 3).to_s + '>').
			gsub(/<(\/?)h2>/, '<\1h' + (reduce_headings + 2).to_s + '>').
			gsub(/<(\/?)h1>/, '<\1h' + (reduce_headings + 1).to_s + '>').
			html_safe
	end

	def truncate(text)
		strip_tags(text.gsub('>', '> ')).gsub(/^(.{40,60})\s.*$/m, '\1&hellip;').html_safe
	end

	def textarea(name, value = nil, options = {})
		id = name.to_s.gsub('[', '_').gsub(']', '')
		label_id = "#{id}-label"
		description_id = nil
		html = ''

		if options[:label] == false
			label_id = options[:labelledby]
		elsif options[:label].present?
			html += label_tag(id, nil, id: label_id) do
				_(options[:label], :t, vars: options[:vars] || {})
			end
		else
			html += label_tag(id, nil, id: label_id)
		end

		if options[:help].present?
			description_id ||= "#{id}-desc"
			html += content_tag(:div, _(options[:help], :s, 2), id: description_id, class: 'input-field-help')
		end

		if options[:warning].present?
			description_id ||= "#{id}-desc"
			html += content_tag(:div, _(options[:warning], :s, 2), id: description_id, class: 'warning-info')
		end

		aria = {}
		aria[:labeledby] = label_id if label_id.present?
		aria[:describedby] = description_id if description_id.present?
		if options[:plain]
			html += (text_area_tag name, value,
				id: id,
				lang: options[:lang],
				aria: aria)
		else
			html += content_tag(:div, value.present? ? value.html_safe : '',
					id: id,
					class: 'textarea',
					data: { name: name, 'edit-on': options[:edit_on] || :load },
					lang: options[:lang],
					aria: aria,
					tabindex: 0
				)

			add_stylesheet :editor
			add_inline_script :pen
			add_inline_script :markdown
			add_inline_script :editor
		end

		html = content_tag(:div, html.html_safe, class: ['text-area-field', 'input-field']).html_safe
		html += _original_content(options[:original_value], options[:original_lang]) if options[:original_value].present?

		return html.html_safe
	end

	def fieldset(name, options = {}, &block)
		html = ''
		label_id = nil
		description_id = nil

		if options[:heading].present?
			label_id ||= "#{name.to_s}-label"
			html += content_tag(:h3, _(options[:heading], :t, vars: options[:vars] || {}), id: label_id)
		end

		if options[:help].present?
			description_id ||= "#{name.to_s}-desc"
			html += content_tag(:div, _(options[:help], :s, 2), class: 'input-field-help', id: description_id)
		end

		(html + content_tag(:fieldset, content_tag(:div, class: :fieldgroup, &block).html_safe,
				aria: {
					labeledby: label_id,
					describedby: description_id
				}
			)
		).html_safe
	end

	def selectfield(name, value, select_options, options = {})
		textfield(name, value, options.merge({type: :select, options: select_options}))
	end

	def telephonefield(name, value, options = {})
		textfield(name, value, options.merge({type: :telephone}))
	end

	def numberfield(name, value, options = {})
		textfield(name, value, options.merge({type: :number}))
	end

	def emailfield(name, value, options = {})
		textfield(name, value, options.merge({type: :email}))
	end

	def textfield(name, value, options = {})
		html = ''
		id = name.to_s.gsub('[', '_').gsub(']', '')
		description_id = nil
		
		if options[:heading].present?
			description_id ||= "#{id.to_s}-desc"
			html += content_tag(:h3, _(options[:heading], :t, vars: options[:vars] || {}), id: description_id)
		end

		if options[:help].present?
			description_id ||= "#{id.to_s}-desc"
			html += content_tag(:div, _(options[:help], :s, 2, vars: options[:vars] || {}), class: 'input-field-help', id: description_id)
		end

		html += show_errors name, value

		if options[:label].present?
			html += label_tag(id) do
				_(options[:label], :t, vars: options[:vars] || {})
			end
		elsif options[:label] != false
			html += label_tag id
		end
		input_options = {
				id: id,
				required: options[:required],
				lang: options[:lang],
				min: options[:min],
				max: options[:max],
				aria: description_id ? { describedby: description_id } : nil
			}

		case name
		when :address
			input_options[:autocomplete] = 'address-line1'
		when :name
			input_options[:autocomplete] = 'name'
		when :location
			input_options[:autocomplete] = 'address-level2'
		when :email
			input_options[:autocomplete] = 'email'
		when :phone
			input_options[:autocomplete] = 'tel'
		end

		case options[:type]
		when :select
			html += select_tag(name, options_for_select(options[:options], value), input_options)
		else
			html += send("#{(options[:type] || :text).to_s}_field_tag", name, value, input_options)
		end

		html = content_tag(:div, html.html_safe,
				class: [
					"#{(options[:type] || :text).to_s}-field",
					'input-field',
					options[:big] ? 'big' : nil,
					options[:small] ? 'small' : nil,
					options[:stretch] ? 'stretch-item' : nil,
					(@errors || {})[name].present? ? 'has-error' : nil
			])

		html += _original_content(options[:original_value], options[:original_lang]) if options[:original_value].present?

		return html.html_safe
	end

	def radiobuttons(name, boxes, value, label_key, options = {})
		checkboxes(name, boxes, [value], label_key, options.merge({radiobuttons: true}))
	end

	def checkbox(name, value, label_key, options = {})
		checkboxes(name, [true], value, label_key, options)
	end

	def unique_id(id)
		id = id.to_s.gsub('[', '_').gsub(']', '')

		@_ids ||= {}
		@_ids[id] ||= 0

		new_id = id
		
		if @_ids[id] > 0
			new_id += "--#{@_ids[id]}"
		end

		@_ids[id] += 1

		return new_id
	end

	def checkboxes(name, boxes, values, label_key, options = {})
		html = ''

		label_id = nil
		description_id = nil

		if options[:heading].present?
			label_id ||= unique_id("#{name.to_s}-label")
			html += content_tag(:h3, _(options[:heading], :t), id: label_id)
		end

		help = nil

		if options[:help].present?
			description_id ||= unique_id("#{name.to_s}-desc")
			help = content_tag(:div, _(options[:help], :s, 2), class: 'input-field-help', id: description_id)
		end

		html += help if help.present? && !options[:right_help]

		boxes_html = ''

		is_single = !values.is_a?(Array)
		unless boxes.length > 0 && boxes.first.is_a?(Integer)
			values = values.present? ? values.map(&:to_s) : [] unless is_single
			boxes = boxes.map(&:to_s)
		end
		boxes.each do | box |
			checked = (is_single ? values.present? : values.include?(box))
			values -= [box] if checked && !is_single
			id = nil
			if options[:radiobuttons].present?
				id = unique_id("#{name.to_s}_#{box}")
				boxes_html += radio_button_tag(name, box, checked, id: id)
			else
				_name = (is_single ? name : "#{name.to_s}[#{box}]")
				id = unique_id(_name)
				boxes_html += check_box_tag(_name, 1, checked, data: { toggles: options[:toggles] }.compact, id: id)
			end
			if is_single
				label = _(label_key.to_s)
			elsif box.is_a?(Integer)
				label = I18n.t(label_key.to_s)[box]
			else
				label = _("#{label_key.to_s}.#{box}")
			end
					
			boxes_html += label_tag(id, label)
		end

		if options[:other].present? && !is_single
			id = nil
			if options[:radiobuttons].present?
				id = unique_id("#{name.to_s}_other")
				boxes_html += radio_button_tag(name, :other, values.present?, id: id)
			else
				_name = "#{name.to_s}[other]"
				id = unique_id(_name)
				boxes_html += check_box_tag(_name, 1, values.present?, id: id)
			end
			boxes_html += label_tag id,
				content_tag(:div,
					text_field_tag("other_#{name.to_s}", values.first, placeholder: (_"#{label_key}.other"), required: values.present?),
					class: 'other')
		end

		html += content_tag(:fieldset, content_tag(:div, boxes_html.html_safe,
				class: [
					'check-box-field',
					'input-field',
					options[:vertical] ? 'vertical' : nil,
					options[:inline] ? 'inline' : nil,
					options[:small] ? 'small' : nil
				].compact).html_safe,
				aria: {
					labeledby: label_id,
					describedby: description_id
				},
				class: [
					options[:centered] ? 'centered' : nil,
					options[:right_help] ? 'right-help' : nil
				].compact
			)

		html += help if help.present? && options[:right_help]

		return html.html_safe
	end

	def comment(comment)
		content_tag(:div, class: 'comment-body') do
			content_tag(:h4, comment.user.name, class: 'comment-title') +
			content_tag(:time, time(comment.created_at, :default), datetime: comment.created_at.to_s) +
			content_tag(:div, class: 'comment-text') do
				markdown comment.comment
			end
		end
	end

	private
		def _original_content(value, lang)
			content_tag(:div, (
					content_tag(:h4, _('translate.content.Translation_of')) +
					content_tag(:div, value, class: 'value', lang: lang)
				).html_safe, class: 'original-text')
		end

		def _form_field(type, name, value, options)
			if type == 'check_box'
				self.send(type + '_tag', name, "1", value, options)
			else
				self.send(type + '_tag', name, value, options)
			end
		end
end
