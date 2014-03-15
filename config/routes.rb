BikeBike::Application.routes.draw do

  resources :events

  resources :event_types

  resources :workshop_requested_resources

  resources :workshop_facilitators

  resources :workshops

	#resources :conference_registration_responses

	#resources :conference_registrations

	#resources :conference_registraton_form_fields

	resources :registration_form_fields

	#resources :conference_admins

	#resources :conference_host_organizations

	resources :conferences, :param => 'slug' do
		get :hosts
		get :registration
		get :workshops
		get :registration
		#resources :registrations, :path => 'registration' do
		#	get :form, on: :collection
		#end
		get 'registration/form' => 'conferences#registration', :sub_action => "form", as: 'registration_form'
		get 'registration/form/register' => 'conferences#registration', :sub_action => "register", as: 'registration_register'
		get 'registration/form/stats' => 'conferences#registration', :sub_action => "stats", as: 'registration_stats'
		post :nonhosts
		post 'registration/form/add-field' => 'conferences#add_field', as: 'registration_add_field'
		post 'registration/form/remove-field' => 'conferences#remove_field', as: 'registration_remove_field'
		post 'registration/form/reorder' => 'conferences#reorder', as: 'registration_reorder'
	end

	#resources :user_organization_relationships

	resources :organizations, :param => 'slug' do
		get :members
		get :identity
		post :nonmembers
	end

	resources :users
	resources :user_sessions

	#resources :organization_statuses

	resources :conference_types

	resources :workshop_streams
	resources :workshop_resources
	resources :workshop_presentation_styles

	resources :locations

	post '/translate/' => 'pages#translate'
	post '/location/territories/' => 'pages#location_territories'

	get		'login' => 'user_sessions#new', :as => :login
	post	'logout' => 'user_sessions#destroy', :as => :logout
	get		'register'  => 'users#new', :as => 'register'

	root 'pages#home'

end
