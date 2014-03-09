class WorkshopStreamsController < ApplicationController
  before_action :set_workshop_stream, only: [:show, :edit, :update, :destroy]

  # GET /workshop_streams
  def index
    @workshop_streams = WorkshopStream.all
  end

  # GET /workshop_streams/1
  def show
  end

  # GET /workshop_streams/new
  def new
    @workshop_stream = WorkshopStream.new
  end

  # GET /workshop_streams/1/edit
  def edit
  end

  # POST /workshop_streams
  def create
    @workshop_stream = WorkshopStream.new(workshop_stream_params)

    if @workshop_stream.save
      redirect_to @workshop_stream, notice: 'Workshop stream was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /workshop_streams/1
  def update
    if @workshop_stream.update(workshop_stream_params)
      redirect_to @workshop_stream, notice: 'Workshop stream was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /workshop_streams/1
  def destroy
    @workshop_stream.destroy
    redirect_to workshop_streams_url, notice: 'Workshop stream was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_workshop_stream
      @workshop_stream = WorkshopStream.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def workshop_stream_params
      params.require(:workshop_stream).permit(:name, :slug, :info)
    end
end
