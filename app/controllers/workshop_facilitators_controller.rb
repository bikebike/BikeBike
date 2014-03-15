class WorkshopFacilitatorsController < ApplicationController
  before_action :set_workshop_facilitator, only: [:show, :edit, :update, :destroy]

  # GET /workshop_facilitators
  def index
    @workshop_facilitators = WorkshopFacilitator.all
  end

  # GET /workshop_facilitators/1
  def show
  end

  # GET /workshop_facilitators/new
  def new
    @workshop_facilitator = WorkshopFacilitator.new
  end

  # GET /workshop_facilitators/1/edit
  def edit
  end

  # POST /workshop_facilitators
  def create
    @workshop_facilitator = WorkshopFacilitator.new(workshop_facilitator_params)

    if @workshop_facilitator.save
      redirect_to @workshop_facilitator, notice: 'Workshop facilitator was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /workshop_facilitators/1
  def update
    if @workshop_facilitator.update(workshop_facilitator_params)
      redirect_to @workshop_facilitator, notice: 'Workshop facilitator was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /workshop_facilitators/1
  def destroy
    @workshop_facilitator.destroy
    redirect_to workshop_facilitators_url, notice: 'Workshop facilitator was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_workshop_facilitator
      @workshop_facilitator = WorkshopFacilitator.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def workshop_facilitator_params
      params.require(:workshop_facilitator).permit(:user_id, :workshop_id, :role)
    end
end
