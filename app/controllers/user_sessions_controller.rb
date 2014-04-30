class UserSessionsController < ApplicationController
	def new
		session[:return_to] ||= request.referer
		@user = User.new
	end

	def create
		if @user = login(params[:email], params[:password])
			redirect_to session.delete(:return_to) || 'pages#home'
		else
			flash.now[:alert] = "Login failed"
			render action: "new"
		end
	end

	def destroy
		logout
		redirect_to(:users, notice: 'Logged out!')
	end
end
