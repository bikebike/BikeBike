module ActiveRecord
	class PremissionDenied < RuntimeError
	end
end

class ApplicationController < LinguaFrancaApplicationController
	include ScheduleHelper

	# Prevent CSRF attacks by raising an exception.
	# For APIs, you may want to use :null_session instead.
	protect_from_forgery with: :exception, :except => [:do_confirm, :js_error]

	before_filter :capture_page_info

	@@test_host
	@@test_location

	def capture_page_info
		if request.method == "GET" && (params[:controller] != 'application' || params[:action] != 'contact')
			session[:last_request]
			request_info = {
				'params' => params,
				'request' => {
					'remote_ip'    => request.remote_ip,
					'uuid'         => request.uuid,
					'original_url' => request.original_url,
					'env'          => Hash.new
				}
			}
			request.env.each do | key, value |
				request_info['request']['env'][key.to_s] = value.to_s
			end
			session['request_info'] = request_info
		end
		# set the translator to the current user if we're logged in
		I18n.config.translator = current_user
		I18n.config.callback = self

		# get the current confernece and set it globally
		@conference = Conference.order("start_date DESC").first

		# add some style sheets
		@stylesheets ||= Array.new
		# add the translations stylesheet if translating
		@stylesheets << params[:controller] if params[:controller] == 'translations'

		@_inline_scripts ||= []
		@_inline_scripts << Rails.application.assets.find_asset('main.js').to_s

		ActionMailer::Base.default_url_options = {:host => "#{request.protocol}#{request.host_with_port}"}

		if request.post? && params[:action] == 'do_confirm'
			halt_redirection!
		end

		@alt_lang_urls = {}
		I18n.backend.enabled_locales.each do |locale|
			locale = locale.to_s
			@alt_lang_urls[locale] = view_context.url_for_locale(locale) # don't show the current locale
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
		error_404(status: 404)
	end

	def error_404(args = {})
		params[:_original_action] = params[:action]
		params[:action] = 'error-404'
		@page_title = 'page_titles.404.Page_Not_Found'
		@main_title = 'error.404.title'
		render 'application/404', args
	end

	def do_403(template = nil)
		@template = template
		@page_title ||= 'page_titles.403.Access_Denied'
		@main_title ||= @page_title
		params[:_original_action] = params[:action]
		params[:action] = 'error-403'
		render 'application/permission_denied', status: 403
	end

	def error_500(exception)
		@page_title = 'page_titles.500.An_Error_Occurred'
		@main_title = 'error.500.title'
		params[:_original_action] = params[:action]
		params[:action] = 'error-500'
		render 'application/500', status: 500
	end

	def js_error
		# send and email if this is production
		report = "A JavaScript error has occurred on <code>#{params[:location]}</code>"
		if params[:location] == params[:url]
			report += " on line <code>#{params[:lineNumber]}</code>"
		else
			report += " in <code>#{params[:url]}:#{params[:lineNumber]}</code>"
		end

		begin
			# log the error
			logger.info exception.to_s
			logger.info exception.backtrace.join("\n")

			UserMailer.send_mail(:error_report) do 
				[
					"A JavaScript error has occurred",
					report,
					params[:message],
					nil,
					request,
					params,
					current_user,
				]
			end if Rails.env.preview? || Rails.env.production?
		rescue exception2
			logger.info exception2.to_s
			logger.info exception2.backtrace.join("\n")
		end
		render json: {}
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

	def locale_not_enabled!(locale = nil)
		locale_not_available!(locale)
	end
	
	def locale_not_available!(locale = nil)
		# set_default_locale
		params[:_original_action] = params[:action]
		params[:action] = 'error-locale-not-available'
		@page_title = 'page_titles.404.Locale_Not_Available'
		@main_title_vars = { vars: { language: view_context.language(locale) } }
		@main_title = 'error.locale_not_available.title'
		render 'application/locale_not_available', status: 404
	end

	rescue_from StandardError do |exception|
		# log the error
		logger.info exception.to_s
		logger.info exception.backtrace.join("\n")

		# send and email if this is production
		suppress(Exception) do
			UserMailer.send_mail(:error_report) do 
				[
					"An error has occurred in #{Rails.env}",
					nil,
					exception.to_s,
					exception.backtrace.join("\n"),
					request,
					params,
					current_user,
				]
			end if Rails.env.preview? || Rails.env.production?
		end

		# raise the error if we are in development so that we can debug it
		raise exception if Rails.env.development?

		# show the error page
		error_500 exception
	end

	def generate_confirmation(user, url, expiry = nil)
		if user.is_a? String
			user = User.find_by_email(user)

			# if the user doesn't exist, just show them a 403
			do_403 unless user.present?
		end
		expiry ||= (Time.now + 12.hours)
		session[:confirm_uid] = user.id
		UserMailer.send_mail! :email_confirmation do
			EmailConfirmation.create(user_id: user.id, expiry: expiry, url: url)
		end
	end

	def user_settings
		@main_title = @page_title = 'page_titles.user_settings.Your_Account'
	end

	def contact
		@main_title = @page_title = 'page_titles.contact.Contact_Us'
	end

	def contact_send
		email_list = ['Godwin <goodgodwin@hotmail.com>']
		
		if params[:reason] == 'conference'

			@conference.organizations.each do | org |
				org.users.each do | user |
					email_list << user.named_email
				end
			end
		end

		UserMailer.send_mail(:contact) do 
			[
				current_user || params[:email],
				params[:subject],
				params[:message],
				email_list
			]
		end

		request_info = session['request_info'] || { 'request' => request, 'params' => params }
		UserMailer.send_mail(:contact_details) do 
			[
				current_user || params[:email],
				params[:subject],
				params[:message],
				request_info['request'],
				request_info['params']
			]
		end

		redirect_to contact_sent_path
	end

	def contact_sent
		@main_title = @page_title = 'page_titles.contact.Contact_Us'
		@sent = true
		render 'contact'
	end

	def update_user_settings
		return do_403 unless logged_in?
		current_user.firstname = params[:name]
		current_user.lastname = nil
		current_user.languages = params[:languages].keys
		current_user.is_subscribed = params[:email_subscribe].present?
		current_user.save
		redirect_to settings_path
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

			unless user
				# not really a good UX so we should fix this later
				#do_404
				#return
				user = User.new(:email => params[:email])
				user.save!
			end

			# generate the confirmation, send the email and show the 403
			referrer = params[:dest] || request.referer.gsub(/^.*?\/\/.*?\//, '/')
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

    def on_translation_change(object, data, locale, translator_id)
		translator = User.find(translator_id)
		mailer = "#{object.class.table_name.singularize}_translated"

		if object.respond_to?(:get_translators)
			object.get_translators(data, locale).each do |id, user|
				if user.id != current_user.id && user.id != translator_id
					UserMailer.send_mail mailer do
						{ :args => [object, data, locale, user, translator] }
					end
				end
			end
		end
	end

	def on_translatable_content_change(object, data)
		mailer = "#{object.class.table_name.singularize}_original_content_changed"
		
		if object.respond_to?(:get_translators)
			object.get_translators(data).each do |id, user|
				if user.id != current_user.id
					UserMailer.send_mail mailer do
						{ :args => [object, data, user, current_user] }
					end
				end
			end
		end
	end

	def i18n_exception(str, exception, locale, key)
		# log it
		logger.info "Missing translation found for: #{key}"

		# send and email if this is production
		begin
			UserMailer.send_mail(:error_report) do 
				[
					"A missing translation found in #{Rails.env}",
					"<p>A translation for <code>#{key}</code> in <code>#{locale.to_s}</code> was found. The text that was rendered to the user was:</p><blockquote>#{str || 'nil'}</blockquote>",
					exception.to_s,
					nil,
					request,
					params,
					current_user,
				]
			end if Rails.env.preview? || Rails.env.production?
		rescue exception2
			logger.info exception2.to_s
			logger.info exception2.backtrace.join("\n")
		end
	end
end
