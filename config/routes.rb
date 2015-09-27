BikeBike::Application.routes.draw do

    get   '/organizations/json' => 'organizations#json', :as => :organizations_json

    get   '/conferences/:slug/edit' => 'conferences#edit', :as => :edit_conference
    post  '/conferences/:slug/save' => 'conferences#save', :as => :save_conference

    match '/conferences/:slug/register' => 'conferences#register', :as => :register, via: [:get, :post]
    match '/conferences/:slug/broadcast' => 'conferences#broadcast', :as => :broadcast, via: [:get, :post]
    get   '/conferences/:slug/stats' => 'conferences#stats', :as => :stats
    get   '/conferences/:slug/register/:button/:confirmation_token' => 'conferences#register', :as => :register_paypal_confirm
    
    get   '/conferences/:slug/schedule' => 'conferences#schedule', :as => :schedule
    get   '/conferences/:slug/schedule/edit' => 'conferences#edit_schedule', :as => :edit_schedule
    post  '/conferences/:slug/schedule/save' => 'conferences#save_schedule', :as => :save_schedule
    
    get   '/conferences/:slug/schedule/location/add' => 'conferences#add_location', :as => :add_location
    post  '/conferences/:slug/schedule/location/save' => 'conferences#save_location', :as => :save_location
    get   '/conferences/:slug/schedule/location/:id' => 'conferences#view_location', :as => :view_location
    get   '/conferences/:slug/schedule/location/:id/edit' => 'conferences#edit_location', :as => :edit_location

    get   '/conferences/:slug/schedule/event/add' => 'conferences#add_event', :as => :add_event
    post  '/conferences/:slug/schedule/event/save' => 'conferences#save_event', :as => :save_event
    get   '/conferences/:slug/schedule/event/:id' => 'conferences#view_event', :as => :view_event
    get   '/conferences/:slug/schedule/event/:id/edit' => 'conferences#edit_event', :as => :edit_event

    get   '/conferences/:slug/workshops' => 'conferences#workshops', :as => :workshops
    match '/conferences/:slug/workshops/create' => 'conferences#create_workshop', :as => :create_workshop, via: [:get, :post]
    post  '/conferences/:slug/workshops/save' => 'conferences#save_workshop', :as => :save_workshop
    get   '/conferences/:slug/workshops/:workshop_id' => 'conferences#view_workshop', :as => :view_workshop
    post  '/conferences/:slug/workshops/:workshop_id/toggle-interest' => 'conferences#toggle_workshop_interest', :as => :toggle_workshop_interest
    match '/conferences/:slug/workshops/:workshop_id/edit' => 'conferences#edit_workshop', :as => :edit_workshop, via: [:get, :post]
    match '/conferences/:slug/workshops/:workshop_id/delete' => 'conferences#delete_workshop', :as => :delete_workshop, via: [:get, :post]
    get   '/conferences/:slug/workshops/:workshop_id/facilitate' => 'conferences#facilitate_workshop', :as => :facilitate_workshop
    post  '/conferences/:slug/workshops/:workshop_id/facilitate_request' => 'conferences#facilitate_request', :as => :facilitate_workshop_request
    get   '/conferences/:slug/workshops/:workshop_id/facilitate_request/:user_id/:approve_or_deny' => 'conferences#approve_facilitate_request', :as => :approve_facilitate_workshop_request
    get   '/conferences/:slug/workshops/:workshop_id/facilitate/sent' => 'conferences#sent_facilitate_request', :as => :sent_facilitate_workshop
    post  '/conferences/:slug/workshops/:workshop_id/add_facilitator' => 'conferences#add_workshop_facilitator', :as => :workshop_add_facilitator

    get   '/robots.txt' => 'application#robots', :as => :robots_txt
    get   '/humans.txt' => 'application#humans', :as => :humans_txt

    get   '/confirm/:token' => 'application#confirm', :as => :confirm
    match '/doconfirm' => 'application#do_confirm', :as => :do_confirm, via: [:get, :post]
    #post '/doconfirm' => 'application#do_confirm', :as => :do_confirm
    post  '/logout' => 'application#user_logout', :as => :logout
    post  '/translator-request' => 'application#translator_request', :as => :translator_request

	get   '/error_404' => 'application#error_404'
	get   '/about' => 'application#about', :as => :about
	get   '/policy' => 'application#policy', :as => :policy
	root  'application#home', :as => :home

end
