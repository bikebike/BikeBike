class ConferenceHostOrganizationsController < ApplicationController
  before_action :set_conference_host_organization, only: [:show, :edit, :update, :destroy]

  # GET /conference_host_organizations
  def index
    @conference_host_organizations = ConferenceHostOrganization.all
  end

  # GET /conference_host_organizations/1
  def show
  end

  # GET /conference_host_organizations/new
  def new
    @conference_host_organization = ConferenceHostOrganization.new
  end

  # GET /conference_host_organizations/1/edit
  def edit
  end

  # POST /conference_host_organizations
  def create
    @conference_host_organization = ConferenceHostOrganization.new(conference_host_organization_params)

    if @conference_host_organization.save
      redirect_to @conference_host_organization, notice: 'Conference host organization was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /conference_host_organizations/1
  def update
    if @conference_host_organization.update(conference_host_organization_params)
      redirect_to @conference_host_organization, notice: 'Conference host organization was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /conference_host_organizations/1
  def destroy
    @conference_host_organization.destroy
    redirect_to conference_host_organizations_url, notice: 'Conference host organization was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_conference_host_organization
      @conference_host_organization = ConferenceHostOrganization.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def conference_host_organization_params
      params.require(:conference_host_organization).permit(:conference_id, :organization_id, :order)
    end
end
