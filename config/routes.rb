BikeBike::Application.routes.draw do

	#resources :events
	#resources :event_types
	#resources :workshop_requested_resources
	#resources :workshop_facilitators
	#resources :registration_form_fields

	# resources :conference_types, :param => :type, :path => '/conferences', :as => :conference, :except => :index do
	# 	resources :conferences, :param => :slug, :path => '/' do
	# 		#get :hosts
	# 		#get :registration
	# 		#get :registration
 #            #resources :workshops, :param => 'slug'
	# 		#get :register, :param => 'step'
 #            #post 'register/next' => 'conferences#register_submit'
 #            # get 'register/workshop-test/' => 'conferences#workshop_test'
 #            match 'register(/:step)' => 'conferences#register', via: [:get, :post]
 #            get 'register/confirm/:confirmation_token' => 'conferences#register_confirm'
 #            match 'register/pay-registration/:confirmation_token' => 'conferences#register_pay_registration', via: [:get, :post]
 #            get 'register/paypal-confirm/:confirmation_token' => 'conferences#register_paypal_confirm'
 #            get 'register/paypal-cancel/:confirmation_token' => 'conferences#register_paypal_cancel'
 #            get 'registrations' => 'conferences#registrations'
 #            #patch 'register/step/:step' => 'conferences#register_step'
	# 		#resources :registrations, :path => 'registration' do
	# 		#	get :form, on: :collection
	# 		#end
	# 		#get 'registration/form' => 'conferences#registration', :sub_action => "form", as: 'registration_form'
	# 		#get 'registration/form/register' => 'conferences#registration', :sub_action => "register", as: 'registration_register'
	# 		#get 'registration/form/stats' => 'conferences#registration', :sub_action => "stats", as: 'registration_stats'
	# 		#post :nonhosts
	# 		#post 'registration/form/add-field' => 'conferences#add_field', as: 'registration_add_field'
	# 		#post 'registration/form/remove-field' => 'conferences#remove_field', as: 'registration_remove_field'
 #            #post 'registration/form/reorder' => 'conferences#reorder', as: 'registration_reorder'
			
 #            #post 'registration/form/reorder' => 'conferences#reorder', as: 'registration_reorder'
	# 	end
	# end

	# resources :conferences, :only => :index

	# resources :organizations, :param => 'slug' do
	# 	get :members
	# 	get :identity
	# 	get :json
	# 	post :nonmembers
	# end

	# resources :users
	# resources :user_sessions


	#resources :workshop_streams
	#resources :workshop_resources
	#resources :workshop_presentation_styles

	#resources :locations

	# post '/translate/' => 'pages#translate'
	# post '/location/territories/' => 'pages#location_territories'
	
	# get '/translations/:lang', to: 'pages#translations'
	# get '/translations', to: 'pages#translation_list'

	# get		'login' => 'user_sessions#new', :as => :login
	# post	'logout' => 'user_sessions#destroy', :as => :logout
	# get		'register'  => 'users#new', :as => 'register'
  
	# post "oauth/callback" => "oauths#callback"
	# get "oauth/callback" => "oauths#callback"
	# get "oauth/:provider" => "oauths#oauth", :as => :auth_at_provider

    get '/organizations/json' => 'organizations#json', :as => :organizations_json
    match '/conferences/:slug/register' => 'conferences#register', :as => :register, via: [:get, :post]
    match '/conferences/:slug/broadcast' => 'conferences#broadcast', :as => :broadcast, via: [:get, :post]
    get '/conferences/:slug/stats' => 'conferences#stats', :as => :stats
	get '/conferences/:slug/register/:button/:confirmation_token' => 'conferences#register', :as => :register_paypal_confirm
    get '/conferences/:slug/workshops' => 'conferences#workshops', :as => :workshops
    match '/conferences/:slug/workshops/create' => 'conferences#create_workshop', :as => :create_workshop, via: [:get, :post]
    post '/conferences/:slug/workshops/save' => 'conferences#save_workshop', :as => :save_workshop
    get '/conferences/:slug/workshops/:workshop_id' => 'conferences#view_workshop', :as => :view_workshop
    match '/conferences/:slug/workshops/:workshop_id/edit' => 'conferences#edit_workshop', :as => :edit_workshop, via: [:get, :post]
    match '/conferences/:slug/workshops/:workshop_id/delete' => 'conferences#delete_workshop', :as => :delete_workshop, via: [:get, :post]

    get '/robots.txt' => 'application#robots', :as => :robots_txt
    get '/humans.txt' => 'application#humans', :as => :humans_txt
    # get 'resources' => 'pages#resources'
    # 
    get '/confirm/:token' => 'application#confirm', :as => :confirm
    #post '/doconfirm' => 'application#do_confirm', :as => :do_confirm
    match '/doconfirm' => 'application#do_confirm', :as => :do_confirm, via: [:get, :post]
    post '/logout' => 'application#user_logout', :as => :logout
    post '/translator-request' => 'application#translator_request', :as => :translator_request

	get '/error_404' => 'application#error_404'
	get '/about' => 'application#about', :as => :about
	get '/policy' => 'application#policy', :as => :policy
	root 'application#home', :as => :home

end
