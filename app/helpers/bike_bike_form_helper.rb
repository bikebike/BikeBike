
module BikeBikeFormHelper
	include ActionView::Helpers::FormTagHelper

	TEMPLATE_DIR = 'layouts/fields'

	def check_box_tag(name, value = "1", checked = false, options = {})
		render_field(name, options = get_options(name, options), super(name, value, checked, options), value)
	end

	def color_field_tag(name, value = nil, options = {})
		render_field(name, options = get_options(name, options), super(name, value, options), value)
	end

	def date_field_tag(name, value = nil, options = {})
		render_field(name, options = get_options(name, options), super(name, value, options), value)
	end

	def datetime_field_tag(name, value = nil, options = {})
		render_field(name, options = get_options(name, options), super(name, value, options), value)
	end

	def datetime_local_field_tag(name, value = nil, options = {})
		render_field(name, options = get_options(name, options), super(name, value, options), value)
	end

	def email_field_tag(name, value = nil, options = {})
		render_field(name, options = get_options(name, options), super(name, value, options), value)
	end

	def file_field_tag(name, options = {})
		render_field(name, options = get_options(name, options), super(name, options))
	end

	def hidden_field_tag(name, value = nil, options = {})
		super(name, value, options)
	end

	def month_field_tag(name, value = nil, options = {})
		render_field(name, options = get_options(name, options), super(name, value, options), value)
	end

	def number_field_tag(name, value = nil, options = {})
        options[:_no_wrapper] = true
		render_field(name, options = get_options(name, options), super(name, value, options), value)
	end

	def password_field_tag(name = "password", value = nil, options = {})
		render_field(name, options = get_options(name, options), super(name, value, options), value)
	end

	def phone_field_tag(name, value = nil, options = {})
		render_field(name, options = get_options(name, options), super(name, value, options), value)
	end

	def radio_button_tag(name, value, checked = false, options = {})
		render_field(name, options = get_options(name, options), super(name, value, checked, options), value)
	end

	def range_field_tag(name, value = nil, options = {})
		render_field(name, options = get_options(name, options), super(name, value, options), value)
	end

	def search_field_tag(name, value = nil, options = {})
		render_field(name, options = get_options(name, options), super(name, value, options), value)
	end

	def select_tag(name, option_tags = nil, options = {})
		render_field(name, options = get_options(name, options), super(name, option_tags, options))
	end

	def telephone_field_tag(name, value = nil, options = {})
		render_field(name, options = get_options(name, options), super(name, value, options), value)
	end

	def text_area_tag(name, content = nil, options = {})
		render_field(name, options = get_options(name, options), super(name, content, options), content)
	end

	def text_field_tag(name, value = nil, options = {})
        if options[:_no_wrapper]
            options.delete(:_no_wrapper)
            options[:no_wrapper] = true
        end
		render_field(name, options = get_options(name, options), super(name, value, options), value)
	end

	def time_field_tag(name, value = nil, options = {})
		render_field(name, options = get_options(name, options), super(name, value, options), value)
	end

	def url_field_tag(name, value = nil, options = {})
		render_field(name, options = get_options(name, options), super(name, value, options), value)
	end

	def week_field_tag(name, value = nil, options = {})
		render_field(name, options = get_options(name, options), super(name, value, options), value)
	end

	def country_select_tag(name, value, options={})
		#options[:no_wrapper] = true
		render_field(name, options = get_options(name, options), super(name, value, options), value)
	end

	def subregion_select_tag(name, value, parent_region_or_code, options = {}, html_options = {})
		render_field(name, options = get_options(name, options), super(name, value, parent_region_or_code, options), value)
	end

	#def button_tag
	#def field_set_tag
	#def form_tag
	#def image_submit_tag
	#def label_tag
	#def submit_tag
	#def utf8_enforcer_tag

	# FormHelper methods

	def check_box(object_name, method, options = {}, checked_value = "1", unchecked_value = "0")
		render_field(method, options = get_options(method, options), super(object_name, method, options, checked_value, unchecked_value))
	end

	def color_field(object_name, method, options = {})
		render_field(method, options = get_options(method, options), super(object_name, method, options))
	end

	def date_field(object_name, method, options = {})
		render_field(method, options = get_options(method, options), super(object_name, method, options))
	end

	def datetime_field(object_name, method, options = {})
		render_field(method, options = get_options(method, options), super(object_name, method, options))
	end

	def datetime_local_field(object_name, method, options = {})
		render_field(method, options = get_options(method, options), super(object_name, method, options))
	end

	def email_field(object_name, method, options = {})
		render_field(method, options = get_options(method, options), super(object_name, method, options))
	end

	def file_field(object_name, method, options = {})
		render_field(method, options = get_options(method, options), super(object_name, method, options))
	end

	def hidden_field(object_name, method, options = {})
		super(object_name, method, options)
	end

	def month_field(object_name, method, options = {})
		render_field(method, options = get_options(method, options), super(object_name, method, options), get_value(method, options))
	end

	def number_field(object_name, method, options = {})
        options[:_no_wrapper] = true
		render_field(method, options = get_options(method, options), super(object_name, method, options), get_value(method, options))
	end

	def password_field(object_name, method, options = {})
		render_field(method, options = get_options(method, options), super(object_name, method, options), get_value(method, options))
	end

	def phone_field(object_name, method, options = {})
		render_field(method, options = get_options(method, options), super(object_name, method, options), get_value(method, options))
	end

	def radio_button(object_name, method, tag_value, options = {})
		render_field(method, options = get_options(method, options), super(object_name, method, tag_value, options), get_value(method, options))
	end

	def range_field(object_name, method, options = {})
		render_field(method, options = get_options(method, options), super(object_name, method, options), get_value(method, options))
	end

	def search_field(object_name, method, options = {})
		render_field(method, options = get_options(method, options), super(object_name, method, options), get_value(method, options))
	end

	def telephone_field(object_name, method, options = {})
		render_field(method, options = get_options(method, options), super(object_name, method, options), get_value(method, options))
	end

	def text_area(object_name, method, options = {})
		render_field(method, options = get_options(method, options), super(object_name, method, options), get_value(method, options))
	end

	def text_field(object_name, method, options = {})
        if options[:_no_wrapper]
            options.delete(:_no_wrapper)
            options[:no_wrapper] = true
        end
		render_field(method, options = get_options(method, options), super(object_name, method, options), get_value(method, options))
	end
	
	def time_field(object_name, method, options = {})
		render_field(method, options = get_options(method, options), super(object_name, method, options), get_value(method, options))
	end

	def url_field(object_name, method, options = {})
		render_field(method, options = get_options(method, options), super(object_name, method, options), get_value(method, options))
	end

	def week_field(object_name, method, options = {})
		render_field(method, options = get_options(method, options), super(object_name, method, options), get_value(method, options))
	end

	def form_for(*args, &block)
		@record = args.first

		template = 'errors_' + @record.class.name.underscore
		template = 'errors_default' unless lookup_context.exists?(template, [TEMPLATE_DIR], true)

		( render (TEMPLATE_DIR + '/' + template) ) + super(*args, &block)
	end

	def collection_check_boxes(object, method, collection, value_method, text_method, options = {}, html_options = {}, &block)
		render_field(method, options = get_options(method, options), super(object, method, collection, value_method, text_method, options, html_options, &block), get_value(method, options))
	end

	def collection_radio_buttons(object, method, collection, value_method, text_method, options = {}, html_options = {}, &block)
		render_field(method, options = get_options(method, options), super(object, method, collection, value_method, text_method, options, html_options, &block), get_value(method, options))
	end

	def collection_select(object, method, collection, value_method, text_method, options = {}, html_options = {})
		render_field(method, options = get_options(method, options), super(object, method, collection, value_method, text_method, options, html_options), get_value(method, options))
	end

	def grouped_collection_select(object, method, collection, group_method, group_label_method, option_key_method, option_value_method, options = {}, html_options = {})
		render_field(method, options = get_options(method, options), super(object, method, collection, group_method, group_label_method, option_key_method, option_value_method, options, html_options), get_value(method, options))
	end

	def select(object, method, choices = nil, options = {}, html_options = {}, &block)
		render_field(method, options = get_options(method, options), super(object, method, choices, options, html_options, &block), get_value(method, options))
	end

	def time_zone_select(object, method, priority_zones = nil, options = {}, html_options = {})
		render_field(method, options = get_options(method, options), super(object, method, priority_zones, options, html_options), get_value(method, options))
	end

	def country_select(object, method, priorities_or_options = {}, options_or_html_options = {}, html_options = {})
		if priorities_or_options.is_a? Array
			options = options_or_html_options = get_options(method, priorities_or_options)
		else
			options = priorities_or_options = get_options(method, priorities_or_options)
		end
		render_field(method, options, super(object, method, priorities_or_options, options_or_html_options, html_options), get_value(method, options))
	end

	def subregion_select(object, method, parent_region_or_code, options = {}, html_options = {})
		render_field(method, options = get_options(method, options), super(object, method, parent_region_or_code, options, html_options), get_value(method, options))
	end

	# Custom fields

	def image_field_tag(name, value = nil, options = {})
		render_field(name, options = get_options(name, options), BikeBikeFormHelper.image_field_tag(name, value, options), value)
	end

	def organization_select_field_tag(name, value = nil, options = {})
		render_field(name, options = get_options(name, options), BikeBikeFormHelper.organization_select_field_tag(name, value, options), value)
	end

	def user_select_field_tag(name, value = nil, options = {})
		render_field(name, options = get_options(name, options), BikeBikeFormHelper.user_select_field_tag(name, value, options), value)
	end

	#def grouped_options_for_select
	#def option_groups_from_collection_for_select
	#def options_for_select
	#def options_from_collection_for_select
	#def time_zone_options_for_select

	def form_actions(actions = [])
		BikeBikeFormHelper.form_actions(actions)
	end

	class << self

		def form_actions(actions = [])
			render(:actions, {:actions => actions.is_a?(Array) ? actions : [actions]})
		end

		def image_field_tag(name, value, options, form = nil)
			render(:field_image_field, {:name => name, :value => value, :options => options, :form => form})
		end

		def organization_select_field_tag(name, value, options, form = nil)
			render(:field_organization_select_field, {:name => name, :value => value, :options => options, :form => form})
		end

		def user_select_field_tag(name, value, options, form = nil)
			render(:field_user_select_field, {:name => name, :value => value, :options => options, :form => form})
		end

		def get_options(name, options, type)
			if options[:placeholder] === false
				options.delete(:placeholder)
			elsif (['email_field', 'number_field', 'phone_field', 'search_field', 'telephone_field', 'text_area', 'text_field', 'url_field'].include? type)
				options[:placeholder] ||= I18n.translate('form.placeholder.Enter_your_' + name.to_s)
			end
			return options
		end

		def render_field(type, name, options, html, value = nil)
			options.symbolize_keys!
			if (options.has_key?(:no_wrapper) && options[:no_wrapper]) || /country/.match(name.to_s) && /^subregion_select/.match(type.to_s) || options[:type] == 'hidden'
				return html
			end

			params = Hash.new
			params[:name] = name.to_sym
			params[:options] = options
			params[:html] = html
			params[:type] = type
			params[:value] = value

			template = template_exists?(type) ? type : 'default'
			params[:label_template] = options[:label] === false ? nil : get_label_template(type, options)
			params[:label_position] = options[:label] === false ? :none : label_position(type, options)

			render(template, params)
		end

		def get_label_template(type, options)
			if !options[:label] && /select(_field)?$/.match(type.to_s)
				return nil
			end
			template_exists?('label_' + type) ? type : 'default'
		end

		def label_position(type, options)
			# one of: :before, :after, :inside, or :none
			case type
				when 'image_field'
					return :inside
				when 'organization_select_field'
					return :none
				#when 'select_field'
				#	return :before
			end
			return :before
		end

		private
			def render (template, params)
				view = ActionView::Base.new(ActionController::Base.view_paths, params)
				view.extend ApplicationHelper
				view.render (TEMPLATE_DIR + '/' + template.to_s)
			end

			def template_exists? (template)
				view = ActionView::Base.new(ActionController::Base.view_paths, {})
				view.extend ApplicationHelper
				view.lookup_context.exists?(template, [TEMPLATE_DIR], true)
			end
	end

	private
		def get_type()
			caller[1][/`.*'/][1..-2].gsub(/^(.*?)(_tag)?$/, '\1')
		end

		def get_value(method, options)
			options && options[:object] ? options[:object][method] : nil
		end

		def get_options(name, options)
			options[:_controller] = params[:controller]
			BikeBikeFormHelper.get_options(name, options, get_type())
		end

		def render_field(name, options, html, value = nil)
			BikeBikeFormHelper.render_field(get_type(), name, options, html, value)
		end

	class BikeBikeFormBuilder < ActionView::Helpers::FormBuilder
		ActionView::Base.default_form_builder = BikeBikeFormHelper::BikeBikeFormBuilder
		
		def image_field(method, value, options = {})
			custom_field(method, value, options, 'image_field')
		end
		
		def organization_select_field(method, value, options = {})
			custom_field(method, value, options, 'organization_select_field')
		end

		def user_select_field(method, value, options = {})
			custom_field(method, value, options, 'user_select_field')
		end

		def actions(actions = [])
			BikeBikeFormHelper.form_actions(actions)
		end

		private
			def custom_field(method, value, options, type)
				if defined? params
					options[:_controller] = params[:controller]
				end
				options[:_record] = object
				options = BikeBikeFormHelper.get_options(method, options, type)
				html = BikeBikeFormHelper.send(type + '_tag', method, value, options, self)
				BikeBikeFormHelper.render_field(type, method, options, html, value)
			end
	end
end
