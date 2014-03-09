class RegistrationFormFieldsController < ApplicationController
	before_action :set_registration_form_field, only: [:show, :edit, :update, :destroy]

	# GET /registration_form_fields
	def index
		@registration_form_fields = RegistrationFormField.all
	end

	# GET /registration_form_fields/1
	def show
	end

	# GET /registration_form_fields/new
	def new
		@registration_form_field = RegistrationFormField.new
	end

	# GET /registration_form_fields/1/edit
	def edit
	end

	# POST /registration_form_fields
	def create
		@registration_form_field = RegistrationFormField.new(registration_form_field_params)
		ajax_return(@registration_form_field.save)
	end

	# PATCH/PUT /registration_form_fields/1
	def update
		ajax_return(@registration_form_field.update(registration_form_field_params))
	end

	# DELETE /registration_form_fields/1
	def destroy
		@registration_form_field.destroy
		redirect_to registration_form_fields_url, notice: 'Registration form field was successfully destroyed.'
	end

	private
		def ajax_return(success)
			@registration_form_fields = RegistrationFormField.all
			if success
				@registration_form_field = RegistrationFormField.new
			end
			
			form = render_to_string :partial => 'form'
			list = render_to_string :partial => 'list'
			render json: {form: form, list: list}
		end
		# Use callbacks to share common setup or constraints between actions.
		def set_registration_form_field
			@registration_form_field = RegistrationFormField.find(params[:id])
		end

		# Only allow a trusted parameter "white list" through.
		def registration_form_field_params
			#type = params[:type]
			#allowed = RegistrationFormField::Types[type]
			#allowed << 'field_type'
			rff_params = params.require(:registration_form_field)
			allowed = RegistrationFormField::GetNonOptionKeys(rff_params[:field_type], rff_params)
			p = rff_params.send('permit', *allowed)#permit(:title, :help, :required, :field_type, :options, :is_retired)
			p[:options] = RegistrationFormField::GetOptions(rff_params[:field_type], rff_params).to_json.to_s
			p
		end
end
