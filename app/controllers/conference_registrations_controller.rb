class ConferenceRegistrationsController < ApplicationController
  before_action :set_conference_registration, only: [:show, :edit, :update, :destroy]

  # GET /conference_registrations
  def index
    @conference_registrations = ConferenceRegistration.all
  end

  # GET /conference_registrations/1
  def show
  end

  # GET /conference_registrations/new
  def new
    @conference_registration = ConferenceRegistration.new
  end

  # GET /conference_registrations/1/edit
  def edit
  end

  # POST /conference_registrations
  def create
    @conference_registration = ConferenceRegistration.new(conference_registration_params)

    if @conference_registration.save
      redirect_to @conference_registration, notice: 'Conference registration was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /conference_registrations/1
  def update
    if @conference_registration.update(conference_registration_params)
      redirect_to @conference_registration, notice: 'Conference registration was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /conference_registrations/1
  def destroy
    @conference_registration.destroy
    redirect_to conference_registrations_url, notice: 'Conference registration was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_conference_registration
      @conference_registration = ConferenceRegistration.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def conference_registration_params
      params.require(:conference_registration).permit(:conference_id, :user_id, :is_attending)
    end
end
