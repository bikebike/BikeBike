BikeBike::Application.routes.draw do

  # Conferences
  get   '/conferences' => 'conferences#list', as: :conferences
  
  # Administrator only
  get   '/conferences/new' => 'admin#new', as: :new_conference
  post  '/conferences/save' => 'admin#save', as: :save_conference
  get   '/conferences/:slug/edit' => 'admin#edit', as: :edit_conference
  get   '/conferences/:slug' => 'conferences#view', as: :conference

  # Conference registration
  match '/conferences/:slug/register' => 'conferences#register', as: :register, via: [:get, :post]
  get   '/conferences/:slug/register/:step' => 'conferences#register', as: :register_step
  get   '/conferences/:slug/register/:button/:confirmation_token' => 'conferences#register', as: :register_paypal_confirm
  
  # Conference administratin
  get   '/conferences/:slug/administration' => 'conference_administration#administration', as: :administrate_conference
  get   '/conferences/:slug/administration/:step' => 'conference_administration#administration_step', as: :administration_step
  post  '/conferences/:slug/administration/update/:step' => 'conference_administration#admin_update', as: :administration_update
  get   '/conferences/:slug/administration/events/edit/:id' => 'conference_administration#edit_event', as: :edit_event
  get   '/conferences/:slug/administration/locations/edit/:id' => 'conference_administration#edit_location', as: :edit_location

  # Workshops
  get   '/conferences/:slug/workshops' => 'workshops#workshops', as: :workshops
  match '/conferences/:slug/workshops/create' => 'workshops#create_workshop', as: :create_workshop, via: [:get, :post]
  post  '/conferences/:slug/workshops/save' => 'workshops#save_workshop', as: :save_workshop
  get   '/conferences/:slug/workshops/:workshop_id' => 'workshops#view_workshop', as: :view_workshop
  post  '/conferences/:slug/workshops/:workshop_id/toggle-interest' => 'workshops#toggle_workshop_interest', as: :toggle_workshop_interest
  match '/conferences/:slug/workshops/:workshop_id/edit' => 'workshops#edit_workshop', as: :edit_workshop, via: [:get, :post]
  match '/conferences/:slug/workshops/:workshop_id/translate/:locale' => 'workshops#translate_workshop', as: :translate_workshop, via: [:get, :post]
  match '/conferences/:slug/workshops/:workshop_id/delete' => 'workshops#delete_workshop', as: :delete_workshop, via: [:get, :post]
  post  '/conferences/:slug/workshops/:workshop_id/comment' => 'workshops#add_comment', as: :workshop_comment
  get   '/conferences/:slug/workshops/:workshop_id/facilitate' => 'workshops#facilitate_workshop', as: :facilitate_workshop
  post  '/conferences/:slug/workshops/:workshop_id/facilitate_request' => 'workshops#facilitate_request', as: :facilitate_workshop_request
  get   '/conferences/:slug/workshops/:workshop_id/facilitate_request/:user_id/:approve_or_deny' => 'workshops#approve_facilitate_request', as: :approve_facilitate_workshop_request
  get   '/conferences/:slug/workshops/:workshop_id/facilitate/sent' => 'workshops#sent_facilitate_request', as: :sent_facilitate_workshop
  post  '/conferences/:slug/workshops/:workshop_id/add_facilitator' => 'workshops#add_workshop_facilitator', as: :workshop_add_facilitator

  # User pages
  match '/user/logout' => 'application#user_logout', as: :logout, via: [:get, :post]
  get   '/user' => 'application#user_settings', as: :settings
  post  '/user/update' => 'application#update_user_settings', as: :update_settings
  post  '/user/find' => 'application#find_user', as: :find_user

  # OAuth enpoints
  match '/oauth/callback' => 'oauths#callback', via: [:get, :post]
  get   '/oauth/update' => 'oauths#update', as: :oauth_update
  post  '/oauth/save' => 'oauths#save', as: :oauth_save
  get   '/oauth/:provider' => 'oauths#oauth', as: :auth_at_provider

  # User confirmation pages
  get   '/confirm/:token' => 'application#confirm', as: :confirm
  match '/doconfirm' => 'application#do_confirm', as: :do_confirm, via: [:get, :post]

  # Contact
  get   '/contact' => 'application#contact', as: :contact
  post  '/contact/send' => 'application#contact_send', as: :contact_send
  get   '/contact/sent' => 'application#contact_sent', as: :contact_sent

  # Static pages
  get   '/about' => 'application#about', as: :about
  get   '/policy' => 'application#policy', as: :policy

  # Site info
  get   '/robots.txt' => 'application#robots', as: :robots_txt
  get   '/humans.txt' => 'application#humans', as: :humans_txt

  # Error pages
  post  '/js_error' => 'application#js_error'
  get   '/error_403' => 'application#do_403' unless Rails.env.production?
  get   '/error_404' => 'application#error_404' unless Rails.env.production?
  get   '/error_500' => 'application#error_500' unless Rails.env.production?

  # Home page
  root  'application#home', as: :home

end
