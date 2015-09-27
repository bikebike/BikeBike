module ActiveRecord
	class PremissionDenied < RuntimeError
	end
end

class ApplicationController < LinguaFrancaApplicationController
	include ScheduleHelper

	# Prevent CSRF attacks by raising an exception.
	# For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :exception, :except => [:do_confirm]

	before_filter :capture_page_info

	@@test_host
	@@test_location

	def capture_page_info
		# set the translator to the current user if we're logged in
		I18n.config.translator = current_user

		# get the current confernece and set it globally
		@conference = Conference.order("start_date DESC").first

		# add some style sheets
		@stylesheets ||= Array.new
		# add the translations stylesheet if translating
		@stylesheets << params[:controller] if params[:controller] == 'translations'

		ActionMailer::Base.default_url_options = {:host => "#{request.protocol}#{request.host_with_port}"}

		if request.post? && params[:action] == 'do_confirm'
			halt_redirection!
		end

		# call the base method to detect the language
		super
	end

	def home
		@workshops = Workshop.where(:conference_id => @conference.id)

		if @conference.workshop_schedule_published
			@events = Event.where(:conference_id => @conference.id)
			schedule = get_schedule_data
			@schedule = schedule[:schedule]
			@locations = Hash.new
			EventLocation.where(:conference_id => @conference.id).each do |l|
				@locations[l.id.to_s] = l
			end
			@day_parts = @conference.day_parts ? JSON.parse(@conference.day_parts) : {:morning => 0, :afternoon => 13, :evening => 18}
		end
	end

	def policy
		@is_policy_page = true
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

	def error_404
		render 'application/404'
	end

	def do_403(template = nil)
		@template = template
		render 'application/permission_denied', status: 403
	end

	rescue_from ActiveRecord::RecordNotFound do |exception|
		do_404
	end

	rescue_from ActiveRecord::PremissionDenied do |exception|
		do_403
	end

	rescue_from AbstractController::ActionNotFound do |exception|
		@banner_image = 'grafitti.jpg'
		
		if current_user
			@page_title = nil#'page_titles.Please_Login'
			do_403 'not_a_translator'
			#return
		else
			@page_title = 'page_titles.403.Please_Login'
			do_403 'translator_login'
		end
	end

	def generate_confirmation(user, url, expiry = nil)
		if user.is_a? String
			user = User.find_by_email(user)

			# if the user doesn't exist, just show them a 403
			do_403 unless user
		end
		expiry ||= (Time.now + 12.hours)
		session[:confirm_uid] = user.id
		#confirmation = EmailConfirmation.create(user_id: user.id, expiry: expiry, url: url)
		#UserMailer.email_confirmation(confirmation).deliver_now
		UserMailer.send_mail :email_confirmation do
			{
				:args => EmailConfirmation.create(user_id: user.id, expiry: expiry, url: url)
			}
		end
	end

	def do_confirm(settings = nil)
		settings ||= {:template => 'login_confirmation_sent'}
		if params[:email]
			# see if we've already sent the confirmation email and are just confirming
			#  the email address
			if params[:token]
				user = User.find_by_email(params[:email])
				confirm(user)
				return
			end
			user = User.find_by_email(params[:email])

			if !user
				# not really a good UX so we should fix this later
				#do_404
				#return
				user = User.new(:email => params[:email])
				user.save!
				user = User.find_by_email(params[:email])
			end

			# genereate the confirmation, send the email and show the 403
			referrer = request.referer.gsub(/^.*?\/\/.*?\//, '/')
			generate_confirmation(params[:email], referrer)
			template = 'login_confirmation_sent'
			@page_title ||= 'page_titles.403.Please_Check_Email'

			if (conference = /^\/conferences\/(\w+)\/register\/?$/.match(request.referrer.gsub(/^https?:\/\/.*?\//, '/')))
				@this_conference = Conference.find_by!(slug: conference[1])
				@banner_image = @this_conference.cover_url
				template = 'conferences/email_confirm'
			end
		end
		
		if request.post?
			@banner_image ||= 'grafitti.jpg'
			@page_title ||= 'page_titles.403.Please_Login'

			do_403 (template || 'translator_login')
		else
			do_404
		end
	end

	def confirm(uid = nil)
		@confirmation = EmailConfirmation.find_by_token!(params[:token])

		confirm_user = nil
		if uid.is_a?(User)
			confirm_user = uid
			uid = confirm_user.id
		end
		# check to see if we were given a user id to confirm against
		#  if we were, make sure it was the same one
		if (uid ||= (params[:uid] || session[:confirm_uid]))
			if uid == @confirmation.user_id
				session[:uid] = nil
				confirm_user ||= User.find uid
				auto_login(confirm_user)
			else
				@confirmation.delete
			end

			redirect_to (@confirmation.url || '/')
			return
		end

		@banner_image = 'grafitti.jpg'
		@page_title = 'page_titles.403.Please_Confirm_Email'
		do_403 'login_confirm'
	end

	def translator_request
		@banner_image = 'grafitti.jpg'
		@page_title = 'page_titles.403.Translator_Request_Sent'
		do_403 'translator_request_sent'
	end

	def user_logout
		logout()
		redirect_to (params[:url] || '/')
	end

	def login_user(u)
		auto_login(u)
	end

end
