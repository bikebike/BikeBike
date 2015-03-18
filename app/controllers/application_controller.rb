module ActiveRecord
	class PremissionDenied < RuntimeError
	end
end

class ApplicationController < LinguaFrancaApplicationController
	# Prevent CSRF attacks by raising an exception.
	# For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :exception
	
	#if ENV['RAILS_ENV'] || 'production'
	#	force_ssl only: :success
	#end

	before_filter :capture_page_info

	@@test_host
	@@test_location

	def capture_page_info
		init_vars
		#$page_info = {:path => request.env['PATH_INFO'], :controller => params['controller'], :action => params['action']}
		ActionMailer::Base.default_url_options = {:host => "#{request.protocol}#{request.host_with_port}"}
		#lang = I18n.backend.set_locale (is_test? && @@test_host.present? ? @@test_host : request.host)
		#if lang.blank?
		#	do_404
		#elsif lang != true
		#	@lang = lang
		#	render 'pages/language_not_enabled', status: 404
		#end
	end

	def self.set_host(host)
		@@test_host = host
	end

	def self.set_location(location)
		@@test_location = location#.nil? nil : Geocoder.search(location)
	end

	def self.get_location()
		@@test_location
	end

	def do_404
		render 'pages/404', status: 404
	end

	def do_403
		render 'permission_denied', status: 403
	end

	rescue_from ActiveRecord::RecordNotFound do |exception|
		do_404
	end

	rescue_from ActiveRecord::PremissionDenied do |exception|
		do_403
	end
end
