class WorkshopRequestedResourcesController < ApplicationController
  before_action :set_workshop_requested_resource, only: [:show, :edit, :update, :destroy]

  # GET /workshop_requested_resources
  def index
    @workshop_requested_resources = WorkshopRequestedResource.all
  end

  # GET /workshop_requested_resources/1
  def show
  end

  # GET /workshop_requested_resources/new
  def new
    @workshop_requested_resource = WorkshopRequestedResource.new
  end

  # GET /workshop_requested_resources/1/edit
  def edit
  end

  # POST /workshop_requested_resources
  def create
    @workshop_requested_resource = WorkshopRequestedResource.new(workshop_requested_resource_params)

    if @workshop_requested_resource.save
      redirect_to @workshop_requested_resource, notice: 'Workshop requested resource was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /workshop_requested_resources/1
  def update
    if @workshop_requested_resource.update(workshop_requested_resource_params)
      redirect_to @workshop_requested_resource, notice: 'Workshop requested resource was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /workshop_requested_resources/1
  def destroy
    @workshop_requested_resource.destroy
    redirect_to workshop_requested_resources_url, notice: 'Workshop requested resource was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_workshop_requested_resource
      @workshop_requested_resource = WorkshopRequestedResource.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def workshop_requested_resource_params
      params.require(:workshop_requested_resource).permit(:workshop_id, :workshop_resource_id, :status)
    end
end
