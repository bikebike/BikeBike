module ApplicationHelper
	@@keyQueue = nil
	@@translationsOnThisPage = nil
	@@lastTranslation = nil
	@@allTranslations = nil
	@@no_banner = true

	def ThereAreTranslationsOnThisPage?
		@@translationsOnThisPage
	end

	def get_all_translations
		@@allTranslations
	end

	def title(page_title)
		content_for(:title) { page_title.to_s }
	end

	def banner_image(banner_image)
		@@no_banner = false
		content_for(:banner_image) { banner_image.to_s }
	end

	def banner_attrs(banner_image)
		if banner_image.length > 0
			return {style: 'background-image: url(' + banner_image + ');', class: 'has-image' }
		end
		{class: 'no-image'}
	end

	def has_banner?
		!@@no_banner
	end

	def banner_title(banner_title)
		@@no_banner = false
		content_for(:banner) { ('<div class="row"><h1>' + banner_title.to_s + '</h1></div>').html_safe }
	end

	def page_style(style)
		classes = ['page-style-' + style.to_s]
		if @@no_banner
			classes << 'no-banner'
		end
		if ThereAreTranslationsOnThisPage?
			classes << 'has-translations'
		end
		if params[:controller]
			classes << params[:controller]

			if params[:action]
				classes << params[:controller] + '-' + params[:action]
			end
		end
		content_for(:page_style) { classes.join(' ') }
	end

	def yield_or_default(section, default = '')
		content_for?(section) ? content_for(section) : default
	end

	def _(key, behavior = nil, behavior_size = nil, locale: nil, vars: {}, html: nil, blockData: {}, &block)
		options = vars
		options[:fallback] = true
		if behavior
			options[:behavior] = behavior
			options[:behavior_size] = behavior_size
		end
		if locale
			options[:locale] = locale.to_sym
		end
		#if vars
		#	puts "\nVARS:\t#{vars}\n"
		#end
		I18n.translate(key, options)
		
		#queued_keys = nil
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
		#locale ||= I18n.locale
		begin
			v[:raise] = true
			#v[:locale] = locale.to_sym
			#v[:fallback] = false
			#puts "\nSTART\n"
			options = {:raise => true}
			if locale
				options[:locale] = locale.to_sym
			end
			#puts "\n#{options.to_json.to_s}\n"
			translation['untranslated'] = I18n.translate(key, v, options)
			#puts "\nEND\n"
			translation['lang'] = locale.to_s
			translation['is_translated'] = true

			hash = Hash.new
			translations = Translation.where(["locale = ? AND key LIKE ?", locale.to_s, key + '%']).take(6).each { |o| hash[o.key] = o.value }
			translation['translated'] = hash.to_json.gsub('"', '&quot;')
		rescue I18n::MissingTranslationData
			#begin
			#translation['untranslated'] = I18n.translate!(config.i18n.default_locale, key, vars)
			#translation['lang'] = config.i18n.default_locale.to_s
			#rescue
			#puts "BEHAVIOR:\t#{behavior.to_s}"
			default_translation = I18n::MissingTranslationExceptionHandler.note(key, behavior, behavior_size)
			translation['untranslated'] = default_translation
			#end
		end
		puts "TRANSLATION:\t#{translation.to_json.to_s}"
		return translation
	end

	def _can_translate?()
		false
	end

	def _!()
		if @@keyQueue
			return '%' + @@keyQueue.shift + '%'
		end
	end

	def _?()
		if @@keyQueue
			return '%' + @@keyQueue[0] + '%'
		end
	end

	def field(form, name, type = nil, param = nil, html: nil, help: false, attrs: [], classes: nil, label: nil, placeholder: nil, value: nil, checked: nil, required: false)

		if form.is_a?(Symbol) || form.is_a?(String)
			param = type
			type = name
			name = form
			form = nil
		end

		if attrs && !attrs.is_a?(Array)
			attrs = [attrs]
		end

		attrs_used = 0

		root = 'div'

		lang_key = "form.#{name.to_s}"
		if form
			lang_key = form.object.class.name.underscore.pluralize + '.' + lang_key
		elsif params[:controller]
			lang_key = params[:controller] + '.' + lang_key
		end

		select_prompt = nil
		show_label = !(/^hidden_field/.match(type.to_s))
		label_after = true
		value_attribute = !form

		if /select(_tag)?$/.match(type.to_s)
			if !label
				select_prompt = placeholder || (form ? 'Select a ' + (_ ('form.select_' + name.to_s)) : 'form.Select_one')
				label_html = ''
				show_label = false
			end
			placeholder = nil
			label_after = false
			if param
				if param.is_a?(Array)
					param = options_for_select(param, value)
				elsif param.is_a?(Hash)
					param = options_from_collection_for_select(param, :first, :last, value)
				end
			end
			value_attribute = false
		elsif type.to_s == 'image_field' || type.to_s == 'user_select_field' || type.to_s == 'organization_select_field'
			placeholder = nil
			label_html = ''
			show_label = false
		else
			if /^password/.match(type.to_s)
				placeholder = nil
			elsif !placeholder
				placeholder = (_ 'form.Enter_your_' + name.to_s)
			end
		end

		if show_label
			label_html = eval("(" + (form ? 'form.label' : 'label_tag') + " name, '<span>#{CGI.escapeHTML(_ (label || name.to_s))}</span>'.html_safe)")
		end

		if label === false || !show_label
			label_html = ''
		end

		if /text_area(_tag)?$/.match(type.to_s)
			root = nil
		end

		html_options = nil
		if html
			html_options = ''
			html.each do |key, v|
				html_options += ', ' + key.to_s + ": html[:" + key.to_s + "]"
			end
		end

		if classes
			if classes.is_a?(String)
				classes = [classes]
			end
		else
			classes = []
		end

		if type == :image_field
			form_html = form.label name do
				('<div>' + image_tag(param || 'http://placehold.it/300x300&text=Click%20to%20upload%20an%20Image') + (form.file_field name) + (form.hidden_field (name.to_s + '_cache')) + '</div><span><span>' + name.to_s + '</span></span>').html_safe
			end
		elsif type == :user_select_field
			form_html = form.hidden_field(:id, { class: 'id' }).html_safe
			form_html += form.check_box(:_destroy).html_safe
			form_html += form.label(:_destroy, '×').html_safe
			form_html += form.hidden_field(:user_id, { class: 'user-id'} ).html_safe
			if param && param.id
				form_html += image_tag(param.avatar.url :thumb).html_safe + ('<div class="username">' + param.username + '</div>').html_safe
				if attrs && attrs.length > 0 && attrs[0].is_a?(UserOrganizationRelationship)
					form_html += form.select(:relationship, options_for_select(UserOrganizationRelationship::AllRelationships, attrs[0].relationship), {}, {class: 'small'}).html_safe
					attrs_used += 1
				end
			else
				classes << 'new'
				if attrs && attrs.length > 0 && attrs[0].is_a?(UserOrganizationRelationship)
					form_html += ('<a href="#" class="select-user" data-url="' + url_for(attrs[0].organization) + '">' + image_tag('http://placehold.it/120x120&text=%252B').html_safe + '</a><div class="username"></div>').html_safe
					form_html += form.select(:relationship, options_for_select(UserOrganizationRelationship::AllRelationships, UserOrganizationRelationship::DefaultRelationship), {}, {class: 'small'}).html_safe
					attrs_used += 1
				end
			end
		elsif type == :organization_select_field
			form_html = form.hidden_field(:id, { class: 'id' }).html_safe
			form_html += form.check_box(:_destroy).html_safe
			form_html += form.label(:_destroy, '×').html_safe
			form_html += form.hidden_field(:organization_id, { class: 'organzation-id'} ).html_safe
			if param && param.id
				form_html += image_tag(param.avatar.url :thumb).html_safe + ('<div class="organizationname">' + param.name + '</div>').html_safe
			else
				classes << 'new'
				form_html += ('<a href="#" class="select-organization" data-url="' + url_for(param) + '">' + image_tag('http://placehold.it/120x120&text=%252B').html_safe + '</a><div class="organizationname"></div>').html_safe
			end
		else
			ph = ''
			va = ''
			if value_attribute
				if /^(check_box|radio_button)/.match(type.to_s)
					if checked === nil
						checked = value == "on" || value.to_s == "1"
					end
					if /^(radio_button)/.match(type.to_s)
						va = ', "' + value + '", checked'
					else
						va = ', "1", checked'
					end
				else
					va = ', value'
				end
			end
			if placeholder
				if form
					ph = ", :placeholder => '#{placeholder}'"
				else
					ph = ", placeholder: '#{placeholder}'"
				end
			end
			form_html = (form ? "form.#{type} :#{name}" : "#{type} :#{name}") + va + ph + (param ? ', param' : '')
			attrs.each_index { |i| form_html += (i >= attrs_used ? ', attrs[' + i.to_s + ']' : '') }
			if select_prompt
				if form
					form_html += ', {prompt: select_prompt}'
				else
					form_html += ', prompt: select_prompt'
				end
			end
			form_html += (html_options || '')
			if required
				form_html += ', :required => true'
			end
			form_html = eval(form_html)
			if root
				form_html = "<#{root}>" + form_html + "</#{root}>"
			end
		end

		if help
			form_html = ('<p>' + (_ (lang_key + '.help'), :w, 20) + '</p>').html_safe + form_html.html_safe
		end

		return ("<div class=\"field #{type.to_s.gsub('_', '-').gsub(/\-tag$/, '')} field-#{name.to_s.gsub('_', '-')}#{classes.length > 0 ? ' ' + classes.join(' ') : ''}\">" + (label_after ? '' : label_html) + form_html + (label_after ? label_html : '') + "</div>").html_safe
	end

	def actions(actions = [])
		if !actions.is_a?(Array)
			actions = [actions]
		end

		html = '<div class="actions">'
		actions.each { |action|
			if action == :facebook_sign_in
				html += '<a href="' + url_for(auth_at_provider_path(:provider => :facebook)) + '" class="facebook-sign-in button">' + (_ action.to_s) + '</a>'
			else
				html += '<button id="' + action.to_s + '" name="' + action.to_s + '" type="submit">' + (_ action.to_s) + '</button>'
			end
		}
		html += '</div>'
		html.html_safe
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
				link_html = link_to tab, link || object, :class => c
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

	def p(object, attribute)
		('<p>' + object.send(attribute.to_s).strip.gsub(/\s*\n+\s*/, '</p><p>') + '</p>').html_safe
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
					html += field((id + (is_array ? ('_' + key) : '')).to_sym, options['selection_type'] + '_tag', label: value, value: is_array ? (val ? val[key] : nil) : key, checked: is_array ? (val[key] == "1" || val[key] == "on") : val.to_s == key.to_s, required: f.required)
				end
			else
				html += field(id.to_sym, options['selection_type'] + '_tag', opts, value: val, required: f.required)
			end
		else
			html += field(id.to_sym, options['input_type'] + '_tag', label: false, placeholder: f.help, value: response ? ActiveSupport::JSON.decode(response.data) : nil, required: f.required)
		end

		html.html_safe
	end

	def t(*a)
		_(*a)
	end

	def lookup_ip_location
		if request.remote_ip == '127.0.0.1'
			Geocoder.search(session['remote_ip'] || (session['remote_ip'] = open("http://checkip.dyndns.org").first.gsub(/^.*\s([\d\.]+).*$/s, '\1').gsub(/[^\.\d]/, ''))).first
		else
			request.location
		end
	end

end
