module ActiveRecord
	class PremissionDenied < RuntimeError
	end
end

class Translator
	def can_translate?
		true
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
		I18n.config.translator = Translator.new
		@conference = Conference.order("start_date DESC").first
		@stylesheets ||= Array.new
		@stylesheets << params[:controller] if params[:controller] == 'translations'

		ActionMailer::Base.default_url_options = {:host => "#{request.protocol}#{request.host_with_port}"}
	end

	def home
	end

	def about
	end

	def robots
		robot = is_production? && !is_test_server? ? 'live' : 'dev'
		render :text => File.read("config/robots-#{robot}.txt"), :content_type => 'text/plain'
	end

	def humans
		render :text => File.read("config/humans.txt"), :content_type => 'text/plain'
	end

	def self.set_host(host)
		@@test_host = host
	end

	def self.set_location(location)
		@@test_location = location
	end

	def self.get_location()
		@@test_location
	end

	def do_404
		render 'application/404', status: 404
	end

	def do_403
		render 'application/permission_denied', status: 403
	end

	rescue_from ActiveRecord::RecordNotFound do |exception|
		do_404
	end

	rescue_from ActiveRecord::PremissionDenied do |exception|
		do_403
	end
end
