class ConferenceRegistrationResponsesController < ApplicationController
  before_action :set_conference_registration_response, only: [:show, :edit, :update, :destroy]

  # GET /conference_registration_responses
  def index
    @conference_registration_responses = ConferenceRegistrationResponse.all
  end

  # GET /conference_registration_responses/1
  def show
  end

  # GET /conference_registration_responses/new
  def new
    @conference_registration_response = ConferenceRegistrationResponse.new
  end

  # GET /conference_registration_responses/1/edit
  def edit
  end

  # POST /conference_registration_responses
  def create
    @conference_registration_response = ConferenceRegistrationResponse.new(conference_registration_response_params)

    if @conference_registration_response.save
      redirect_to @conference_registration_response, notice: 'Conference registration response was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /conference_registration_responses/1
  def update
    if @conference_registration_response.update(conference_registration_response_params)
      redirect_to @conference_registration_response, notice: 'Conference registration response was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /conference_registration_responses/1
  def destroy
    @conference_registration_response.destroy
    redirect_to conference_registration_responses_url, notice: 'Conference registration response was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_conference_registration_response
      @conference_registration_response = ConferenceRegistrationResponse.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def conference_registration_response_params
      params.require(:conference_registration_response).permit(:conference_registration_id, :registration_form_field_id, :data)
    end
end
