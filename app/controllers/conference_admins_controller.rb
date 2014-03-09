class ConferenceAdminsController < ApplicationController
  before_action :set_conference_admin, only: [:show, :edit, :update, :destroy]

  # GET /conference_admins
  def index
    @conference_admins = ConferenceAdmin.all
  end

  # GET /conference_admins/1
  def show
  end

  # GET /conference_admins/new
  def new
    @conference_admin = ConferenceAdmin.new
  end

  # GET /conference_admins/1/edit
  def edit
  end

  # POST /conference_admins
  def create
    @conference_admin = ConferenceAdmin.new(conference_admin_params)

    if @conference_admin.save
      redirect_to @conference_admin, notice: 'Conference admin was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /conference_admins/1
  def update
    if @conference_admin.update(conference_admin_params)
      redirect_to @conference_admin, notice: 'Conference admin was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /conference_admins/1
  def destroy
    @conference_admin.destroy
    redirect_to conference_admins_url, notice: 'Conference admin was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_conference_admin
      @conference_admin = ConferenceAdmin.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def conference_admin_params
      params.require(:conference_admin).permit(:conference_id, :user_id)
    end
end
