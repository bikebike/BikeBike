include ApplicationHelper

class UsersController < ApplicationController
	before_action :set_user, only: [:show, :edit, :update, :destroy]

	# GET /users
	def index
		@users = User.all
	end

	# GET /users/1
	def show
	end

	# GET /users/new
	def new
		@user = User.new
	end

	# GET /users/1/edit
	def edit
	end

	# POST /users
	def create
		@user = User.new(user_params)

		if @user.save
			redirect_to @user, notice: 'User was successfully created.'
		else
			render action: 'new'
		end
	end

	# PATCH/PUT /users/1
	def update
		#if !user_params[:password] || user_params[:password].length < 1
		#	puts "\nNo Password! ( " + @user.to_json.to_s + " \n"
		#	user_params[:password] = user_params[:password_confirmation] = 'Oha1otbt!@#'
		#end
		if @user.update(user_params)
			redirect_to @user, notice: 'User was successfully updated.'
		else
			render action: 'edit'
		end
	end

	# DELETE /users/1
	def destroy
		@user.destroy
		redirect_to users_url, notice: 'User was successfully destroyed.'
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_user
			@user = User.find(params[:id])
		end

		# Only allow a trusted parameter "white list" through.
		def session_params
        	params.require(:user).permit(:username, :email, :password, :avatar, :avatar_cache)
        end

		def user_params
			params.require(:user).permit(:username, :email, :password, :password_confirmation, :avatar, :avatar_cache, :remove_avatar)
		end
end
