module TableHelper
  def html_edit_table(excel_data, options = {})
    attributes = { class: options[:class], id: options[:id] }
    attributes[:data] = { 'update-url' => options[:editable] } if options[:editable].present?
    
    if options[:column_names].is_a? Hash
      return content_tag(:table, attributes) do
        max_columns = 0
        column_names = {}
        (content_tag(:thead) do
          headers = ''
          options[:column_names].each do | header_name, columns |
            column_names[header_name] ||= []
            headers += content_tag(:th, excel_data[:keys][header_name].present? ? _(excel_data[:keys][header_name]) : '', colspan: 2)
            row_count = columns.size
            columns.each do | column |
              column_names[header_name] << column
              if (options[:row_spans] || {})[column].present?
                row_count += (options[:row_spans][column] - 1)
                for i in 1...options[:row_spans][column]
                  column_names[header_name] << false
                end
              end
            end
            max_columns = row_count if row_count > max_columns
          end
          content_tag(:tr, headers.html_safe)
        end) + (content_tag(:tbody) do
          rows = ''

          for i in 0...max_columns
            columns_html = ''
            column_names.each do | header_name, columns |
              column = columns[i]
              if column.present?
                attributes = { class: [excel_data[:column_types][column]], data: { 'column-id' => column } }
                if (options[:row_spans] || {})[column].present?
                  attributes[:rowspan] = options[:row_spans][column]
                end
                columns_html += content_tag(:th, excel_data[:keys][column].present? ? _(excel_data[:keys][column]) : '', rowspan: attributes[:rowspan]) + 
                edit_column(nil, column, nil, attributes, excel_data, options)
              elsif column != false
                columns_html += content_tag(:td, ' ', colspan: 2, class: :empty)
              end
            end
            rows += content_tag(:tr, columns_html.html_safe, { class: 'always-edit', data: { key: '' } })
          end
          rows.html_safe
        end)
      end
    else
      return content_tag(:table, attributes) do
        (content_tag(:tbody) do
          rows = ''
          excel_data[:columns].each do |column|
            if (excel_data[:column_types] || {})[column] != :table && ((options[:column_names] || []).include? column)
              rows += content_tag(:tr, { class: 'always-edit', data: { key: '' } }) do
                attributes = { class: [excel_data[:column_types][column]], data: { 'column-id' => column } }
                columns = content_tag(:th, excel_data[:keys][column].present? ? _(excel_data[:keys][column]) : '') + 
                edit_column(nil, column, nil, attributes, excel_data, options)
              end
            end
          end
          rows.html_safe
        end)
      end
    end
  end

  def html_table(excel_data, options = {})
    options[:html] = true
    attributes = { class: options[:class], id: options[:id] }
    attributes[:data] = { 'update-url' => options[:editable] } if options[:editable].present?
    content_tag(:table, attributes) do
      (content_tag(:thead) do
        content_tag(:tr, excel_header_columns(excel_data))
      end) +
      content_tag(:tbody, excel_rows(excel_data, {}, options))
    end
  end

  def excel_table(excel_data)
    format_xls 'table' do
      workbook use_autowidth: true
      format bg_color: '333333'
      format 'td', font_name: 'Calibri', fg_color: '333333'
      format 'th', font_name: 'Calibri', b: true, bg_color: '333333', fg_color: 'ffffff'
      format 'th.sub-table', font_name: 'Calibri', b: true, bg_color: 'DDDDDD', fg_color: '333333'
      format 'td.datetime', num_fmt: 22, font_name: 'Courier New', sz: 10, fg_color: '333333'
      format 'td.date.day', num_fmt: 14, font_name: 'Courier New', sz: 10, fg_color: '333333'
      format 'td.money', num_fmt: 2, font_name: 'Courier New', sz: 10, fg_color: '333333'
      format 'td.number', font_name: 'Courier New', sz: 10, fg_color: '333333'
      format 'td.bold', font_name: 'Calibri', fg_color: '333333', b: true
    end

    content_tag(:table) do
      (content_tag(:thead) do
        content_tag(:tr, excel_header_columns(excel_data))
      end) +
      content_tag(:tbody, excel_rows(excel_data))
    end
  end

  def excel_header_columns(data, padding = {}, class_name = nil)
    columns = ''

    data[:columns].each do |column|
      unless data[:column_types].present? && data[:column_types][column] == :table
        columns += content_tag(:th, data[:keys][column].present? ? _(data[:keys][column]) : '', class: class_name)
      end
    end

    pad_columns(columns, padding, :th)
  end

  def excel_empty_row(data, padding = {})
    columns = ''

    data[:columns].each do |column|
      unless data[:column_types].present? && data[:column_types][column] == :table
        columns += content_tag(:td)
      end
    end

    content_tag(:tr, pad_columns(columns, padding))
  end

  def pad_columns(columns, padding, column_type = :td)
    left = ''

    for i in 1..(padding['left'] || 0)
      left += content_tag(:td)
    end

    right = ''
    for i in 1..(padding['right'] || 0)
      right += content_tag(:td)
    end

    (left + columns + right).html_safe
  end

  def excel_columns(row, data, padding = {}, options = {})
    columns = ''

    data[:columns].each do |column|
      value = row[column].present? ? (_!row[column].to_s) : ''
      class_name = nil
      is_sub_table = false

      if data[:column_types].present? && data[:column_types][column].present?
        if data[:column_types][column] == :table
          is_sub_table = true
        else
          class_name = data[:column_types][column]
        end
      end

      unless is_sub_table
        attributes = { class: [class_name] }
        if options[:html] && row[:html_values].present? && row[:html_values][column].present?
          value = row[:html_values][column]
        end
        
        if options[:editable]
          attributes[:data] = { 'column-id' => column }
        end

        if (options[:column_names] || []).include? column
          attributes[:tabindex] = 0
        end

        columns += content_tag(:td, value, attributes)
      end
    end

    pad_columns(columns, padding)
  end

  def editor_columns(row, data, padding = {}, options = {})
    columns = ''

    data[:columns].each do |column|
      value = row[column].present? ? (_!row[column].to_s) : ''
      class_name = nil
      is_sub_table = false

      if data[:column_types].present? && data[:column_types][column].present?
        if data[:column_types][column] == :table
          is_sub_table = true
        else
          class_name = data[:column_types][column]
        end
      end

      unless is_sub_table
        attributes = { class: [class_name] }
        
        if options[:editable]
          attributes[:data] = { 'column-id' => column }
        end

        if (options[:column_names] || []).include? column
          columns += edit_column(row, column, value, attributes, data, options)
        else
          columns += content_tag(:td, value, attributes)
        end

      end
    end

    pad_columns(columns, padding)
  end

  def edit_column(row, column, value, attributes, data, options)
    attributes[:class] << 'has-editor'
    raw_value = row.present? ? (row[:raw_values][column] || value) : nil

    if row.present? && options[:html] && row[:html_values].present? && row[:html_values][column].present?
      value = row[:html_values][column]
    end

    editor_attributes = { class: 'cell-editor', data: { value: raw_value.to_s } }

    # create the control but add the original value to set the width and height
    editor_value = content_tag(:div, value, class: 'value')
    if (options[:column_options] || {})[column].present?
      value = (editor_value.html_safe + select_tag(column, options_for_select([['', '']] + options[:column_options][column], raw_value), editor_attributes)).html_safe
    elsif data[:column_types][column] == :text
      editor_attributes[:name] = column
      value = (editor_value.html_safe + content_tag(:textarea, raw_value, editor_attributes)).html_safe
    else
      editor_attributes[:name] = column
      editor_attributes[:value] = raw_value
      editor_attributes[:required] = :required if (options[:required_columns] || []).include? column
      type = data[:column_types][column] || :unknown
      editor_attributes[:type] = { money: :number, number: :number, email: :email }[type] || :text
      value = (editor_value.html_safe + content_tag(:input, nil, editor_attributes)).html_safe
    end

    return content_tag(:td, value, attributes)
  end

  def excel_sub_tables(row, data, padding = {}, options = {})
    rows = ''

    # shift the table right
    new_padding = {
      'left' => (padding['right'] || 0) + 1,
      'right' => (padding['right'] || 0) - 1
    }

    data[:columns].each do |column|
      if data[:column_types].present? && data[:column_types][column] == :table
        rows += content_tag(:tr, excel_header_columns(row[column], new_padding, 'sub-table'))
        rows += excel_rows(row[column], new_padding)
        rows += excel_empty_row(row[column], new_padding)
      end

    end

    rows.html_safe
  end

  def excel_rows(data, padding = {}, options = {})
    rows = ''
    data[:data].each do |row|
      attributes = {}
      
      if options[:primary_key].present?
        attributes[:data] = { key: row[options[:primary_key]] }
      end

      attributes[:class] = []
      
      if options[:editable]
        attributes[:class] << :editable
      end
      
      rows += content_tag(:tr, excel_columns(row, data, padding, options), attributes) +
        excel_sub_tables(row, data, padding)
      rows += content_tag(:tr, editor_columns(row, data, padding, options), class: :editor) if options[:editable]
    end
    rows.html_safe
  end

  def registrations_edit_table_options
    {
      id: 'create-table',
      class: ['registrations', 'admin-edit', 'always-editing'],
      primary_key: :id,
      column_names: {
          contact_info: [
              :name,
              :email,
              :is_subscribed,
              :city,
              :preferred_language
            ] + User.AVAILABLE_LANGUAGES.map { |l| "language_#{l}".to_sym },
          questions: [
              :registration_fees_paid,
              :is_attending,
              :arrival,
              :departure,
              :housing,
              :bike,
              :food,
              :companion_email,
              :allergies,
              :other
            ],
          hosting: [
              :can_provide_housing,
              :address,
              :phone,
              :first_day,
              :last_day
            ] + ConferenceRegistration.all_spaces +
            ConferenceRegistration.all_considerations + [
              :notes
            ]
        },
      row_spans: {
          allergies: 3,
          other: 2
        },
      required_columns: [:name, :email],
      editable: administration_update_path(@this_conference.slug, @admin_step),
      column_options: @column_options
    }
  end

  def registrations_table_options
    {
      id: 'search-table',
      class: ['registrations', 'admin-edit'],
      primary_key: :id,
      column_names: [
          :registration_fees_paid,
          :is_attending,
          :is_subscribed,
          :city,
          :preferred_language,
          :arrival,
          :departure,
          :housing,
          :bike,
          :food,
          :companion_email,
          :allergies,
          :other,
          :can_provide_housing,
          :address,
          :phone,
          :first_day,
          :last_day,
          :notes
        ] +
        User.AVAILABLE_LANGUAGES.map { |l| "language_#{l}".to_sym } +
        ConferenceRegistration.all_spaces +
        ConferenceRegistration.all_considerations,
      editable: administration_update_path(@this_conference.slug, @admin_step),
      column_options: @column_options
    }
  end
end
