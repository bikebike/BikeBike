class ApplicationController < ActionController::Base
	# Prevent CSRF attacks by raising an exception.
	# For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :exception

	before_filter :capture_page_info

	def capture_page_info
		$page_info = {:path => request.env['PATH_INFO'], :controller => params['controller'], :action => params['action']}
	end
end
