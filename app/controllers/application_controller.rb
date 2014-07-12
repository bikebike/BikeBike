module ActiveRecord
	class PremissionDenied < RuntimeError
	end
end

class ApplicationController < ActionController::Base
	# Prevent CSRF attacks by raising an exception.
	# For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :exception
	
	#if ENV['RAILS_ENV'] || 'production'
	#	force_ssl only: :success
	#end

	before_filter :capture_page_info

	def capture_page_info
		init_vars
		$page_info = {:path => request.env['PATH_INFO'], :controller => params['controller'], :action => params['action']}
	end

	rescue_from ActiveRecord::RecordNotFound do |exception|
		render 'pages/404', status: 404
	end

	rescue_from ActiveRecord::PremissionDenied do |exception|
		render 'permission_denied', status: 403
	end
end
