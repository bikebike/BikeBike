require 'redcarpet'

module WidgetsHelper

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

  def admin_update_form(options = {}, &block)
    form_tag(administration_update_path(@this_conference.slug, @admin_step), options, &block)
  end

  def interest_button(workshop)
    interested = workshop.interested?(current_user) ? :remove_interest : :show_interest
    id = "#{interested.to_s.gsub('_', '-')}-#{workshop.id}"
    return (off_screen (_"forms.actions.aria.#{interested.to_s}"), id) + 
      (button interested, :value => :toggle_interest, :class => (workshop.interested?(current_user) ? :delete : :add), aria: { labelledby: id })
  end

  def interest_text(workshop)
    if workshop.interested?(current_user)
      return _'articles.workshops.info.you_are_interested_count', :vars => {:count => (workshop.interested_count - 1)}
    end

    return _'articles.workshops.info.interested_count', :vars => {:count => workshop.interested_count}
  end

  def host_guests_table(registration)
    id = registration.id
    html = ''
    first_row = true

    @housing_data[id][:guests].each do |area, guests|
      guest_rows = ''
      space_size = (@housing_data[id][:space][area] || 0)

      if space_size > 0 || guests.size > 0
        guests.each do |guest_id, guest|
          status_html = ''

          @housing_data[id][:guest_data][guest_id][:errors].each do |error, value|
            if value.is_a?(Array)
              value.each do |v|
                status_html += content_tag(:li, _("errors.messages.housing.space.#{error.to_s}", vars: v).html_safe)
              end
            else
              status_html += content_tag(:li, _("errors.messages.housing.space.#{error.to_s}", vars: value).html_safe)
            end
          end

          @housing_data[id][:guest_data][guest_id][:warnings].each do |error, value|
            if value.is_a?(Array)
              value.each do |v|
                status_html += content_tag(:li, _("warnings.messages.housing.space.#{error.to_s}", v).html_safe)
              end
            else
              status_html += content_tag(:li, _("warnings.messages.housing.space.#{error.to_s}", vars: value).html_safe)
            end
          end

          if status_html.present?
            status_html = content_tag(:ul, status_html.html_safe)
          end

          name_html = guest[:guest].user.name

          other = (guest[:guest].housing_data || {})['other']
          other.strip! if other.present?

          name_html += admin_notes(other) if other.present?

          guest_rows += content_tag :tr, id: "hosted-guest-#{guest_id}" do
            (content_tag :td, name_html.html_safe) +
            (content_tag :td do
              (guest[:guest].from + 
              (content_tag :a, (_'actions.workshops.Remove'), href: '#', class: 'remove-guest', data: { guest: guest_id })).html_safe
            end) + admin_status(status_html, :td)
          end
        end

        # add empty rows to represent empty guest spots
        for i in guests.size...space_size
          guest_rows += content_tag :tr, class: 'empty-space' do
            (content_tag :td, '&nbsp'.html_safe, colspan: 2) +
            (content_tag :td)
          end
        end

        status_html = ''
        if @housing_data[id][:warnings].present? && @housing_data[id][:warnings][:space].present? && @housing_data[id][:warnings][:space][area].present?
          @housing_data[id][:warnings][:space][area].each do |w|
            status_html += content_tag(:li, _("warnings.messages.housing.space.#{w.to_s}", ))
          end
        end
        if status_html.present?
          status_html = content_tag(:ul, status_html.html_safe)
        end

        unless first_row
          html += content_tag :tr, class: :spacer do
            content_tag :td, '', colspan: 3
          end
        end

        html += content_tag :tr do
          (content_tag :th, (_"forms.labels.generic.#{area}"), colspan: 2) +
          admin_status(status_html, :th)
        end
        html += guest_rows
        html += content_tag :tr, class: 'place-guest' do
          content_tag :td, class: guests.size >= space_size ? 'full' : nil, colspan: 3 do
            content_tag :a, (_"forms.actions.generic.place_guest_in.#{area}"), class: 'select-guest button small', href: '#', data: { host: id, space: area }
          end
        end

        first_row = false
      end
    end

    content_tag :table, html.html_safe, class: 'host-table'
  end

  def admin_notes(notes)
    content_tag :div, (content_tag :div, paragraph(notes), class: 'notes').html_safe, class: 'admin-notes', tabindex: -1
  end

  def admin_status(status_html, tag = :div)
    content_tag tag, status_html.html_safe, class: "admin-status state #{status_html.present? ? 'un' : ''}happy", tabindex: -1
  end
  
  def host_guests_widget(registration)
    html = ''
    classes = ['host']

    id = registration.id
    @housing_data[id][:guests].each do |area, guests|
      max_space = @housing_data[id][:space][area] || 0

      # don't include the area if the host doesn't want anyone there
      if max_space > 0 || guests.size > 0
        area_name = (_"forms.labels.generic.#{area}")
        status_html = ''
        if @housing_data[id][:warnings].present? && @housing_data[id][:warnings][:space].present? && @housing_data[id][:warnings][:space][area].present?
          @housing_data[id][:warnings][:space][area].each do |w|
            status_html += content_tag(:div, _("warnings.housing.space.#{w.to_s}"), class: 'warning')
          end
        end
        space_html = content_tag(:h5, area_name + _!(" (#{guests.size.to_s}/#{max_space.to_s})") + status_html.html_safe)
        guest_items = ''
        guests.each do |guest_id, guest|
          guest_items += content_tag(:li, guest[:guest].user.name, id: "hosted-guest-#{guest_id}")
        end
        space_html += content_tag(:ul, guest_items.html_safe)

        # see if the space is overbooked
        booked_state = guests.size >= max_space ? (guests.size > max_space ? :overbooked : :booked) : nil

        # let space be overbooked, even bed space can be overbooked if a couple is staying in the bed
        space_html += button :place_guest, type: :button, value: "#{area}:#{id}", class: [:small, 'place-guest', 'on-top-only', booked_state, max_space > 0 ? nil : :unwanted] 

        html += content_tag(:div, space_html, class: [:space, area, max_space > 0 || guests.size > 0 ? nil : 'on-top-only'])
      end
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

  def link_help_dlg(topic, args = {})
    @help_dlg ||= true
    args[:data] ||= {}
    args[:data]['info-title'] = I18n.t("help.headings.#{topic}")
    args[:data]['help-text'] = true
    content_tag(:a, args) do
      (I18n.t('help.link_text') + content_tag(:template, (render "/help/#{topic}"), class: 'message')).html_safe
    end
  end

  def button_with_confirmation(button_name, confirmation_text = nil, args = {})
    if confirmation_text.is_a? Hash
      args = confirmation_text
      confirmation_text = nil
    end
    
    confirmation_text ||= (_"forms.confirmations.#{button_name.to_s}", :p)
    @confirmation_dlg ||= true
    args[:data] ||= {}
    args[:data][:confirmation] = true
    button button_name, args do
      ((_"forms.actions.generic.#{button_name.to_s}") + content_tag(:template, confirmation_text, class: 'message')).html_safe
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

  def companion(registration)
    if registration.housing_data.present? && registration.housing_data['companion'].present?
      companion_user = if registration.housing_data['companion']['id'].present?
                         User.find(registration.housing_data['companion']['id'])
                       else
                         User.find_user(registration.housing_data['companion']['email'])
                       end

      if companion_user.present?
        cr = ConferenceRegistration.where(user_id: companion_user.id, conference_id: registration.conference_id).limit(1).first
        return companion_user if cr.present? && cr.registered?
      end
      return :unregistered
    end
    return nil
  end

  def comment(comment)
    add_inline_script :time
    add_js_translation('datetime.distance_in_words')

    content_tag(:div, class: 'comment-body') do
      content_tag(:h4, _!(comment.user.name), class: 'comment-title') +
      content_tag(:time, time(comment.created_at, :default), datetime: comment.created_at.to_s) +
      content_tag(:div, class: 'comment-text') do
        _!(markdown comment.comment)
      end
    end
  end

  def strong(text)
    content_tag(:strong, text)
  end

  def phone_link(number)
    content_tag(:a, number, href: "tel:#{number}")
  end

  def email_link(email)
    content_tag(:a, email, href: "mailto:#{email}")
  end

  def status_bubble(text, status, attributes = {})
    attributes[:class] ||= []
    attributes[:class] = [attributes[:class]] unless attributes[:class].is_a?(Array)
    attributes[:class] << "#{status}-info"
    content_tag(:div, text.html_safe, attributes)
  end
end
