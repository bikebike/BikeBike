class WorkshopsController < ApplicationController
	before_action :set_workshop, only: [:show, :edit, :update, :destroy]

	# GET /workshops
	def index
		set_conference
		@workshops = Workshop.where(['conference_id = ?', @conference.id])
	end

	# GET /workshops/1
	def show
		set_workshop
		set_conference
	end

	# GET /workshops/new
	def new
		set_conference
		@workshop = Workshop.new
	end

	# GET /workshops/1/edit
	def edit
		set_conference
	end

	# POST /workshops
	def create
		set_conference
		@workshop = Workshop.new(workshop_params)

		if @workshop.save
			redirect_to conference_workshop_path(@conference, @workshop), notice: 'Workshop was successfully created.'
		else
			render action: 'new'
		end
	end

	# PATCH/PUT /workshops/1
	def update
		set_conference
		if @workshop.update(workshop_params)
			redirect_to conference_workshop_path(@conference, @workshop), notice: 'Workshop was successfully updated.'
		else
			render action: 'edit'
		end
	end

	# DELETE /workshops/1
	def destroy
		@workshop.destroy
		redirect_to workshops_url, notice: 'Workshop was successfully destroyed.'
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_workshop
			@workshop = Workshop.find_by(slug: params[:workshop_slug] || params[:slug])
		end

		def set_conference
			@conference = Conference.find_by(slug: params[:conference_slug] || params[:slug])
		end

		# Only allow a trusted parameter "white list" through.
		def workshop_params
			params.require(:workshop).permit(:title, :slug, :info, :conference_id, :workshop_stream_id, :workshop_presentation_style, :min_facilitators, :location_id, :start_time, :end_time)
		end
end
