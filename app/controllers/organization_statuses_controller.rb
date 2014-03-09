class OrganizationStatusesController < ApplicationController
  before_action :set_organization_status, only: [:show, :edit, :update, :destroy]

  # GET /organization_statuses
  def index
    @organization_statuses = OrganizationStatus.all
  end

  # GET /organization_statuses/1
  def show
  end

  # GET /organization_statuses/new
  def new
    @organization_status = OrganizationStatus.new
  end

  # GET /organization_statuses/1/edit
  def edit
  end

  # POST /organization_statuses
  def create
    @organization_status = OrganizationStatus.new(organization_status_params)

    if @organization_status.save
      redirect_to @organization_status, notice: 'Organization status was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /organization_statuses/1
  def update
    if @organization_status.update(organization_status_params)
      redirect_to @organization_status, notice: 'Organization status was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /organization_statuses/1
  def destroy
    @organization_status.destroy
    redirect_to organization_statuses_url, notice: 'Organization status was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_organization_status
      @organization_status = OrganizationStatus.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def organization_status_params
      params.require(:organization_status).permit(:name, :slug, :info)
    end
end
