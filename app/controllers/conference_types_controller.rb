class ConferenceTypesController < ApplicationController
  before_action :set_conference_type, only: [:show, :edit, :update, :destroy]

  # GET /conference_types
  def index
    @conference_types = ConferenceType.all
  end

  # GET /conference_types/1
  def show
  end

  # GET /conference_types/new
  def new
    @conference_type = ConferenceType.new
  end

  # GET /conference_types/1/edit
  def edit
  end

  # POST /conference_types
  def create
    @conference_type = ConferenceType.new(conference_type_params)

    if @conference_type.save
      redirect_to @conference_type, notice: 'Conference type was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /conference_types/1
  def update
    if @conference_type.update(conference_type_params)
      redirect_to @conference_type, notice: 'Conference type was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /conference_types/1
  def destroy
    @conference_type.destroy
    redirect_to conference_types_url, notice: 'Conference type was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_conference_type
      @conference_type = ConferenceType.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def conference_type_params
      params.require(:conference_type).permit(:title, :info)
    end
end
