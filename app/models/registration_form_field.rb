class RegistrationFormField < ActiveRecord::Base
	Types = {
		:single => [:title, :required, :input_type, :help],
		:multiple => [:title, :required, :selection_type, :options, :other, :help]
	}

	Fields = {
		:title => {:control => 'text_field'},
		:input_type => {:control => 'select', :options => [[:text_field, :text_area, :number_field, :date_field, :time_field, :phone_field, :checkbox]], :option => true},
		:selection_type => {:control => 'select', :options => [[:check_box, :radio_button, :select]], :option => true},
		:options => {:control => 'text_area', :option => true},
		:help => {:control => 'text_area'},
		:other => {:control => 'check_box', :option => true},
		:required => {:control => 'check_box'}
	}

	def self.TypesForField(field)
		types = []
		Types.each do |k, t|
			if t.include?(field)
				types << k
			end
		end
		types
	end

	def input_type
		get_from_options 'input_type'
	end

	def selection_type
		get_from_options 'selection_type'
	end

	def other
		get_from_options 'other'
	end

	def self.GetOptions(type, values)
		o = {}
		Fields.each do |k, f|
			if f[:option] && Types[type.to_sym].include?(k)
				o[k] = values[k]
			end
		end
		o
	end

	def self.GetNonOptionKeys(type, values)
		o = []
		Fields.each do |k, f|
			if !f[:option] && Types[type.to_sym].include?(k)
				o << k
			end
		end
		o
	end

	private
		def get_from_options(key)
			if options
				_options = ActiveSupport::JSON.decode(options)
				return _options[key]
			end
			nil
		end
end
