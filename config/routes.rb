BikeBike::Application.routes.draw do

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
    get '/conferences/:slug/edit' => 'conferences#edit', :as => :edit_conference
    post '/conferences/:slug/save' => 'conferences#save', :as => :save_conference

    get '/robots.txt' => 'application#robots', :as => :robots_txt
    get '/humans.txt' => 'application#humans', :as => :humans_txt
    # get 'resources' => 'pages#resources'
    # 
    get '/confirm/:token' => 'application#confirm', :as => :confirm
    match '/doconfirm' => 'application#do_confirm', :as => :do_confirm, via: [:get, :post]
    #post '/doconfirm' => 'application#do_confirm', :as => :do_confirm
    post '/logout' => 'application#user_logout', :as => :logout
    post '/translator-request' => 'application#translator_request', :as => :translator_request

	get '/error_404' => 'application#error_404'
	get '/about' => 'application#about', :as => :about
	get '/policy' => 'application#policy', :as => :policy
	root 'application#home', :as => :home

end
