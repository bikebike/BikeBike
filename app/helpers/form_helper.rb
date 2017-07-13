
module FormHelper
  def off_screen(text, id = nil)
    content_tag(:span, text.html_safe, id: id, class: 'screen-reader-text')
  end

  def translate_fields(object, field_options = {}, options = {})
    html = ''
    nav = ''

    # set the selected locale
    selected_locale = (options[:locale] || object.locale || I18n.locale).to_sym

    I18n.backend.enabled_locales.each do |locale|
      # ses if this should b the selected field
      class_name = selected_locale == locale.to_sym ? 'selected' : nil

      # add the locale to the nav
      nav += content_tag(:li,
          content_tag(:a, _("languages.#{locale}"), href: 'javascript:void(0)'),
        class: class_name, data: { locale: locale }).html_safe

      fields = ''
      field_options.each do |name, __options|
        _options = __options.deep_dup
        # add the field
        value = object.is_a?(Hash) ? object[locale.to_sym] : object.get_column_for_locale!(name, locale, false)

        # use the default value if we need to
        if _options[:default].present? && value.blank?
          value = _(_options[:default], locale: locale)
        end

        _options[:index] = locale
        _options[:lang] = locale
        _options[:parent_options] = { lang: locale }
        type = "#{_options[:type].to_s}"
        _options.delete(:type)

        fields += self.send(type, name, value, _options).html_safe
      end

      html += content_tag(:li, fields.html_safe, class: class_name, data: { locale: locale }).html_safe
    end

    if options[:class].nil?
      options[:class] = []
    elsif options[:class].is_a?(String)
      options[:class] = [options[:class]]
    end
    options[:class] += ['translator', 'multi-field-translator']

    (fieldset(nil, options) do
      content_tag(:ul, nav.html_safe, class: 'locale-select').html_safe + 
      content_tag(:ul, html.html_safe, class: 'text-editors').html_safe
    end).html_safe
  end

  def translate_textarea(name, object, property = nil, options = {})
    html = ''
    nav = ''

    # see if options was passed in as property
    if options.blank? && property.is_a?(Hash)
      options = property
      property = nil
    end

    # set the selected locale
    selected_locale = (options[:locale] || object.locale || I18n.locale).to_sym

    I18n.backend.enabled_locales.each do |locale|
      # ses if this should b the selected field
      class_name = selected_locale == locale.to_sym ? 'selected' : nil

      # add the locale to the nav
      nav += content_tag(:li,
          content_tag(:a, _("languages.#{locale}"), href: 'javascript:void(0)'),
        class: class_name, data: { locale: locale }).html_safe
      
      # add the field
      value = object.is_a?(Hash) ? object[locale.to_sym] : object.get_column_for_locale!(name, locale, false)

      # use the default value if we need to
      if options[:default].present? && value.blank?
        value = _(options[:default], locale: locale)
      end

      html += content_tag(:li, textarea(name, value, {
          label: false,
          edit_on: options[:edit_on],
          parent_options: {
            lang: locale
          },
          index: locale
        }).html_safe, class: class_name, data: { locale: locale }).html_safe
    end

    if options[:class].nil?
      options[:class] = []
    elsif options[:class].is_a?(String)
      options[:class] = [options[:class]]
    end
    options[:class] += ['translator']

    (fieldset(name, options) do
      content_tag(:ul, nav.html_safe, class: 'locale-select').html_safe + 
      content_tag(:ul, html.html_safe, class: 'text-editors').html_safe
    end).html_safe
  end

  def textarea(name, value = nil, options = {})
    id = unique_id(name)
    label_id = "#{id}-label"
    description_id = nil
    html = ''

    if options[:heading].present?
      label_id = "#{name.to_s}-label" unless options[:label]
      html += content_tag(:h3, _(options[:heading], :t, vars: options[:vars] || {}), id: label_id)
    end

    if options[:label] == false
      label_id = options[:labelledby]
    elsif options[:label].present?
      html += label_tag([name, id], nil, id: label_id) do
        _(options[:label], :t, vars: options[:vars] || {})
      end
    else
      html += label_tag([name, id], nil, id: label_id)
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
    aria[:labelledby] = label_id if label_id.present?
    aria[:describedby] = description_id if description_id.present?
    css_class = [
        options[:short] === true ? :short : nil
      ].compact

    html_name = name.to_s + (options[:index] ? "[#{options[:index]}]" : '')
    if options[:plain]
      html += (text_area_tag html_name, value,
          id: id,
          lang: options[:lang],
          aria: aria,
          class: css_class
        )
    else
      html += content_tag(:div,
        content_tag(:div, (value || '').html_safe, class: :editor).html_safe,
          id: id,
          data: { name: html_name },
          lang: options[:lang],
          aria: aria,
          tabindex: 0,
          class: [:textarea] + css_class
        )

      add_stylesheet 'quill.css'
      add_javascript :quill
      add_inline_script :editor
    end

    parent_options = options[:parent_options] || {}
    if parent_options[:class].nil?
      parent_options[:class] = []
    elsif parent_options[:class].is_a?(String)
      parent_options[:class] = [parent_options[:class]]
    end

    parent_options[:class] += ['text-area-field', 'input-field']
    html = content_tag(:div, html.html_safe, parent_options).html_safe
    html += _original_content(options[:original_value], options[:original_lang]) if options[:original_value].present?

    return html.html_safe
  end

  def fieldset(name = nil, options = {}, &block)
    html = ''
    label = ''
    description = ''
    description_id = nil
    errors = ''

    if name.present?
      if options[:label] != false
        label = content_tag(:legend,
          _((
            options[:label].is_a?(String) ?
            options[:label] :
            "forms.labels.generic.#{name}"), :t, vars: options[:vars] || {}))
      end

      if options[:help].present?
        description_id = unique_id("#{name.to_s}-desc")
        description = content_tag(:div, _(options[:help], :s, 2), class: 'input-field-help', id: description_id)
      end

      errors = (show_errors name)
    end

    html = label + errors + description + content_tag(:div, class: :fieldgroup, &block)

    aria = description_id.present? ? { describedby: description_id } : nil
    (content_tag(:fieldset, html.html_safe,
        aria: aria,
        class: ((options[:class] || []) + [
            options[:inline] ? :inline : nil,
            options[:inline_label] ? 'inline-label' : nil,
            errors.present? ? 'has-error' : nil
          ]).compact
      )
    ).html_safe
  end

  def selectfield(name, value, select_options, options = {})
    unless select_options.first.is_a?(Array)
      so = select_options
      select_options = []
      so.each do |opt|
        if opt.is_a?(Array)
          select_options << opt
        else
          select_options << [ I18n.t("forms.options.#{name.to_s}.#{opt.to_s}"), opt]
        end
      end
    end
    textfield(name, value, options.merge({type: :select, options: select_options}))
  end

  def telephonefield(name, value, options = {})
    textfield(name, value, options.merge({type: :telephone}))
  end

  def numberfield(name, value, options = {})
    textfield(name, value, options.merge({type: :number}))
  end

  def searchfield(name, value, options = {})
    textfield(name, value, options.merge({type: :search}))
  end

  def userfield(name, value, options = {})
    # eventually this will be a dynamic field to find users, for now we'll just use emails
    # add_inline_script :userfield
    emailfield(name, value, options)# .merge({
    #    parent_options: { class: ['user-field'] },
    #    after: content_tag(:div, '', class: 'user-name')
    #  }))
  end

  def emailfield(name, value, options = {})
    textfield(name, value, options.merge({type: :email}))
  end

  def filefield(name, value, options = {})
    textfield(name, value, options.merge({type: :file}))
  end

  def passwordfield(name, value, options = {})
    textfield(name, value, options.merge({type: :password}))
  end

  def textfield(name, value, options = {})
    html = ''
    id = unique_id(name)
    html_name = name.to_s + (options[:index] ? "[#{options[:index]}]" : '')
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

    if options[:warning].present?
      description_id ||= "#{id}-desc"
      html += content_tag(:div, _(options[:warning], :s, 2), id: description_id, class: 'warning-info')
    end

    inside_label = ''

    if options[:type] == :file
      inside_label = (content_tag(:div, class: 'file-field-selector') do
        (options[:preview] ? content_tag(:img, nil, src: value.present? ? value.url : nil).html_safe : '').html_safe +
        content_tag(:div, (value.present? ? File.basename(value.url) : (_'forms.labels.generic.no_file_selected')), class: 'file-field-name ' + (value.present? ? 'selected' : 'unselected')).html_safe +
        content_tag(:a, (_'forms.actions.generic.select_file'), class: :button)
      end)
    end

    label_text = nil
    if options[:label].present?
      label_text = _(options[:label], :t, vars: options[:vars] || {})
    elsif options[:label] != false
      label_text = (_"forms.labels.generic.#{name}")
    elsif options[:type] == :select || options[:type] == :file
      # add an empty label so that the drop down button will still appear
      label_text = ''
    end

    label_options = {}
    # let the label be selected if the input is hidden
    label_options[:tabindex] = 0 if options[:type] == :file

    unless label_text.nil?
      html += label_tag id, (label_text + inside_label).html_safe
    end

    input_options = {
        id: id,
        required: Rails.env.test? || Rails.env.development? ? false : options[:required],
        readonly: options[:readonly] == true ? :readonly : nil,
        lang: options[:lang],
        min: options[:min],
        max: options[:max],
        step: options[:step],
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
    when :paypal_email_address, :paypal_username, :paypal_password, :paypal_signature
      input_options[:autocomplete] = 'off'
    end

    case options[:type]
    when :select
      option_list = options_for_select(options[:options], value)

      # make sure that we have an empty option if the select is required
      if options[:required] && options[:options].first.present? && options[:options].first.last.present?
        option_list = ('<option value="">&nbsp;</option>' + option_list).html_safe
      end
      html += select_tag(html_name, option_list, input_options)
    when :file
      add_inline_script :filefield
      input_options[:tabindex] = '-1'
      html += off_screen(file_field_tag html_name, input_options)
    else
      input_options[:autocomplete] = 'off' if options[:type] == :search
      html += send("#{(options[:type] || :text).to_s}_field_tag", html_name, value, input_options)
    end

    if options[:after].present?
      html += options[:after].html_safe
    end

    html = content_tag(:div, html.html_safe,
        class: [
          "#{(options[:type] || :text).to_s}-field",
          'input-field',
          value.present? ? nil : 'empty',
          options[:big] ? 'big' : nil,
          options[:small] ? 'small' : nil,
          options[:stretch] ? 'stretch-item' : nil,
          options[:full] ? 'full' : nil,
          options[:inline_label] ? 'inline-label' : nil,
          (@errors || {})[name].present? ? 'has-error' : nil
      ].compact + (((options[:parent_options] || {})[:class]) || []))

    html += _original_content(options[:original_value], options[:original_lang]) if options[:original_value].present?

    return html.html_safe
  end

  def radiobuttons(name, boxes, value, label_key = '', options = {})
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

  def checkboxes(name, boxes, values, label_key = '', options = {})
    html = ''
    boxes.map! { |box| box.is_a?(String) ? box.to_sym : box }
    values.map! { |value| value.is_a?(String) ? value.to_sym : value } if values.is_a?(Array)

    label_id = nil
    description_id = nil

    if options[:heading].present?
      label_id ||= unique_id("#{name.to_s}-label")
      html += content_tag(:h3, _(options[:heading], :t, vars: options[:vars] || {}), id: label_id)
    end

    help = nil

    if options[:help].present?
      description_id ||= unique_id("#{name.to_s}-desc")
      help = content_tag(:div, _(options[:help], :s, 2), class: 'input-field-help', id: description_id)
    end

    html += help if help.present? && !options[:right_help]

    boxes_html = ''

    labels = nil
    is_single = !values.is_a?(Array)
    if boxes.length > 0
      if boxes.first.is_a?(Array)
        labels = boxes.map(&:first) unless label_key == false
        boxes = boxes.map(&:last)
      end
    elsif !boxes.first.is_a?(Integer)
      values = values.present? ? values.map(&:to_s) : [] unless is_single
      boxes = boxes.map(&:to_s)
    end

    # convert the required value into a pure boolean
    required = !!options[:required]

    boxes.each_with_index do |box, i|
      checked = (is_single ? values.present? : values.include?(box))
      values -= [box] if checked && !is_single
      id = nil
      if options[:radiobuttons].present?
        id = unique_id("#{name.to_s}_#{box}")
        boxes_html += radio_button_tag(name, box, checked, id: id, required: required)
      else
        _name = (is_single ? name : "#{name.to_s}[#{box}]")
        id = unique_id(_name)
        boxes_html += check_box_tag(_name, 1, checked, data: { toggles: options[:toggles] }.compact, id: id, required: required)
      end
      
      # we only need the required attribute on one element
      required = false

      if label_key == false
        boxes_html += label_tag(id, '')
      else
        if labels.present?
          label = labels[i]
        elsif is_single
          label = options[:translate] == false ? label_key.to_s : _(label_key.to_s)
        elsif box.is_a?(Integer)
          label = I18n.t(label_key.to_s)[box]
        else
          label = options[:translate] == false ? box : _("#{label_key.to_s}.#{box}")
        end
            
        boxes_html += label_tag(id, label)
      end
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
          options[:small] ? 'small' : nil,
          options[:big] ? 'big' : nil
        ].compact).html_safe,
        aria: {
          labelledby: label_id,
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

  def button(value = nil, options = {}, &block)
    if !block_given? && (value.nil? || value.is_a?(Symbol))
      return button_tag(I18n.t("forms.actions.generic.#{(value || :button)}"), options)
    end

    button_tag(value, options, &block)
  end

  def calendar_day_select(name, value, date_range, highlight_range = nil)
    months = {}
    date_range.to_a.each do |d|
      unless months[d.month].present?
        months[d.month] = [nil] * d.wday
      end
      months[d.month] << d
    end

    rows = []
    empty_cell = content_tag(:td, '').html_safe
    month_names = I18n.t('date.month_names')
    day_names = content_tag(:tr, I18n.t('date.abbr_day_names').map { |day| content_tag(:th, day).html_safe }.join.html_safe).html_safe

    months.each do |month, days|
      rows << content_tag(:tr, content_tag(:th, month_names[month], colspan: 7).html_safe, class: 'month').html_safe
      rows << day_names
      weekdays = []
      days.each do |date|
        if date.nil?
          weekdays << empty_cell
        else
          class_name = ['unstyled']
          if value == date
            class_name << 'selected'
          end
          if highlight_range.present? && highlight_range.include?(date)
            class_name << 'during-conference'
          end
          weekdays << content_tag(:td,
              content_tag(:button, date.day.to_s, name: :date, value: date.to_s, class: class_name).html_safe
            ).html_safe
        end
        if date.present? && date.wday >= 6
          rows << content_tag(:tr, weekdays.join.html_safe).html_safe if weekdays.present?
          weekdays = []
        end
      end
      weekdays += [empty_cell] * (7 - weekdays.length)
      rows << content_tag(:tr, weekdays.join.html_safe).html_safe if weekdays.present?
    end
    return content_tag(:table, rows.join.html_safe, class: :calendar).html_safe
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
      belongs_to_periods << :before_plus_one if day <= (conference.start_date + 1.day)
      belongs_to_periods << :after_minus_one if day >= (conference.end_date - 1.day)
      belongs_to_periods << :during if day >= conference.start_date && day <= conference.end_date
      days << [date(day.to_date, format || :span_same_year_date_1), day.to_date] if belongs_to_periods.include?(period)
    end
    return days
  end

  def registration_status_options_list(conference = nil)
    conference ||= @this_conference || @conference
    return [] unless conference

    options = Array.new
    [:closed, :pre, :open].each do |opt|
      options << [(_"forms.labels.generic.registration_statuses.#{opt}"), opt]
    end

    return options
  end

  def month_select(value = nil, args = {})
    options = (1..12).to_a.map { |month| [ (I18n.t "date.#{args[:format] || 'month_names'}")[month], month ] }
    selectfield args[:name] || :month, value, options, args
  end

  def month_day_select(value = nil, args = {})
    options = (1..31).to_a.map { |day| [ day, day ] }
    selectfield args[:name] || :month_day, value, options, args
  end

  def day_select(value = nil, args = {})
    selectfield :day, value, conference_days_options_list(:during, nil, args[:format]), args
  end

  def hour_select(value = nil, args = {}, start_time = 8, end_time = 23.5, step = 0.5)
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

  def contact_reason_select
    reasons = []
    [:website, :conference].each do |reason|
      reasons << [ _("forms.labels.generic.reasons.#{reason.to_s}"), reason ]
    end
    [['Something about the website', :website]]
    selectfield :reason, nil, reasons, required: true, heading: 'articles.contact.headings.reason', label: false, full: true
  end

  def block_select(value = nil, args = {})
    blocks = {}
    @workshop_blocks.each_with_index do |info, block|
      info['days'].each do |day|
        blocks[(day.to_i * 10) + block] = [ "#{(I18n.t 'date.day_names')[day.to_i]} Block #{block + 1}", "#{day}:#{block}" ]
      end
    end
    selectfield :workshop_block, value, blocks.sort.to_h.values, args
  end

  def location_select(value = nil, args = {})
    locations = []
    if @this_conference.event_locations.present?
      @this_conference.event_locations.each do |location|
        locations << [ location.title, location.id ] unless ((args[:invalid_locations] || []).include? location.id)
      end
    end
    selectfield :event_location, value, locations, args
  end

  def location_name(id)
    begin
      location = EventLocation.find(id)
    rescue
      return ''
    end
    return '' unless location.present?
    return location.title
  end

  def host_options_list(hosts)
    options = [[nil, nil]]
    hosts.each do |id, registration|
      options << [registration.user.name, id]
    end
    return options
  end

  def registration_step_menu
    steps = current_registration_steps(@registration)
    return '' unless steps.present? && steps.length > 1

    pre_registration_steps = ''
    post_registration_steps = ''
    post_registration = false

    steps.each do |step|
      text = _"articles.conference_registration.headings.#{step[:name].to_s}"
      
      if step[:name] == :workshops
        post_registration = true
      end

      h = content_tag :li, class: [step[:enabled] ? :enabled : nil, @register_template == step[:name] ? :current : nil, post_registration ? :post : :pre].compact do
        if step[:enabled]
          content_tag :div, (link_to text, register_step_path(@this_conference.slug, step[:name])).html_safe, class: :step
        else
          content_tag :div, text, class: :step
        end
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
            pre_registration_steps.html_safe +
            post_registration_steps.html_safe
          end).html_safe
        end
      end
    )

    return html.html_safe
  end

  def broadcast_options(conference = nil)
    conference ||= @this_conference || @conference

    options = [
      :registered,
      :pre_registered,
      :workshop_facilitators,
      :unregistered,
      :housing_providers,
      :guests,
      :all
    ]

    if conference.registration_status != :open
      options -= [:registered, :guests]
      options -= [:pre_registered] unless conference.registration_status != :pre
    end

    return options
  end

  def show_errors(field, value = nil)
    return '' unless @errors && @errors[field].present?

    error_txt = _"errors.messages.fields.#{field.to_s}.#{@errors[field]}", :s, vars: { value: value }
    
    content_tag(:div, error_txt, class: 'field-error').html_safe
  end

  private
    def _original_content(value, lang)
      content_tag(:div, (
          content_tag(:h4, _('translate.content.Translation_of')) +
          content_tag(:div, value, class: 'value', lang: lang)
        ).html_safe, class: 'original-text')
    end
end
