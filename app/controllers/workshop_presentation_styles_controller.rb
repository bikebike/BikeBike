class WorkshopPresentationStylesController < ApplicationController
  before_action :set_workshop_presentation_style, only: [:show, :edit, :update, :destroy]

  # GET /workshop_presentation_styles
  def index
    @workshop_presentation_styles = WorkshopPresentationStyle.all
  end

  # GET /workshop_presentation_styles/1
  def show
  end

  # GET /workshop_presentation_styles/new
  def new
    @workshop_presentation_style = WorkshopPresentationStyle.new
  end

  # GET /workshop_presentation_styles/1/edit
  def edit
  end

  # POST /workshop_presentation_styles
  def create
    @workshop_presentation_style = WorkshopPresentationStyle.new(workshop_presentation_style_params)

    if @workshop_presentation_style.save
      redirect_to @workshop_presentation_style, notice: 'Workshop presentation style was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /workshop_presentation_styles/1
  def update
    if @workshop_presentation_style.update(workshop_presentation_style_params)
      redirect_to @workshop_presentation_style, notice: 'Workshop presentation style was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /workshop_presentation_styles/1
  def destroy
    @workshop_presentation_style.destroy
    redirect_to workshop_presentation_styles_url, notice: 'Workshop presentation style was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_workshop_presentation_style
      @workshop_presentation_style = WorkshopPresentationStyle.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def workshop_presentation_style_params
      params.require(:workshop_presentation_style).permit(:name, :slug, :info)
    end
end
