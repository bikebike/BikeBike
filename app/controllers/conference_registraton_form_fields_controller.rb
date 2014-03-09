class ConferenceRegistratonFormFieldsController < ApplicationController
  before_action :set_conference_registraton_form_field, only: [:show, :edit, :update, :destroy]

  # GET /conference_registraton_form_fields
  def index
    @conference_registraton_form_fields = ConferenceRegistratonFormField.all
  end

  # GET /conference_registraton_form_fields/1
  def show
  end

  # GET /conference_registraton_form_fields/new
  def new
    @conference_registraton_form_field = ConferenceRegistratonFormField.new
  end

  # GET /conference_registraton_form_fields/1/edit
  def edit
  end

  # POST /conference_registraton_form_fields
  def create
    @conference_registraton_form_field = ConferenceRegistratonFormField.new(conference_registraton_form_field_params)

    if @conference_registraton_form_field.save
      redirect_to @conference_registraton_form_field, notice: 'Conference registraton form field was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /conference_registraton_form_fields/1
  def update
    if @conference_registraton_form_field.update(conference_registraton_form_field_params)
      redirect_to @conference_registraton_form_field, notice: 'Conference registraton form field was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /conference_registraton_form_fields/1
  def destroy
    @conference_registraton_form_field.destroy
    redirect_to conference_registraton_form_fields_url, notice: 'Conference registraton form field was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_conference_registraton_form_field
      @conference_registraton_form_field = ConferenceRegistratonFormField.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def conference_registraton_form_field_params
      params.require(:conference_registraton_form_field).permit(:conference_id, :registration_form_field_id, :order)
    end
end
