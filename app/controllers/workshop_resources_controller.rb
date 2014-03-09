class WorkshopResourcesController < ApplicationController
  before_action :set_workshop_resource, only: [:show, :edit, :update, :destroy]

  # GET /workshop_resources
  def index
    @workshop_resources = WorkshopResource.all
  end

  # GET /workshop_resources/1
  def show
  end

  # GET /workshop_resources/new
  def new
    @workshop_resource = WorkshopResource.new
  end

  # GET /workshop_resources/1/edit
  def edit
  end

  # POST /workshop_resources
  def create
    @workshop_resource = WorkshopResource.new(workshop_resource_params)

    if @workshop_resource.save
      redirect_to @workshop_resource, notice: 'Workshop resource was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /workshop_resources/1
  def update
    if @workshop_resource.update(workshop_resource_params)
      redirect_to @workshop_resource, notice: 'Workshop resource was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /workshop_resources/1
  def destroy
    @workshop_resource.destroy
    redirect_to workshop_resources_url, notice: 'Workshop resource was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_workshop_resource
      @workshop_resource = WorkshopResource.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def workshop_resource_params
      params.require(:workshop_resource).permit(:name, :slug, :info)
    end
end
