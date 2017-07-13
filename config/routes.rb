BikeBike::Application.routes.draw do

  # Conferences
  scope :conferences do
    root 'conferences#list', as: :conferences

    get 'new' => 'administration#new', as: :new_conference
    post 'save' => 'administration#save', as: :save_conference

    scope ':slug' do
      root 'conferences#view', as: :conference
      
      get 'edit' => 'administration#edit', as: :edit_conference
  
      # Registration
      scope :register do
        root 'conferences#register', as: :register, via: [:get, :post]
        # post 'update' => 'conferences#registration_update', as: :registration_update
        
        get ':step' => 'conferences#register', as: :register_step
      end
      
      # Administration
      scope :administration do
        root 'conference_administration#administration', as: :administrate_conference

        get ':step' => 'conference_administration#administration_step', as: :administration_step
        get 'stats/:conference_slug' => 'conference_administration#previous_stats', as: :previous_stats
        post 'update/:step' => 'conference_administration#admin_update', as: :administration_update
        get 'events/edit/:id' => 'conference_administration#edit_event', as: :edit_event
        get 'locations/edit/:id' => 'conference_administration#edit_location', as: :edit_location
        get 'check_in/:id' => 'conference_administration#check_in', as: :check_in, constraints: { id: /.+/ }
      end

      # Workshops
      scope :workshops do
        root 'workshops#workshops', as: :workshops

        match 'create' => 'workshops#create_workshop', as: :create_workshop, via: :all
        post 'save' => 'workshops#save_workshop', as: :save_workshop

        scope ':workshop_id' do
          root 'workshops#view_workshop', as: :view_workshop

          match 'edit' => 'workshops#edit_workshop', as: :edit_workshop, via: :all
          match 'delete' => 'workshops#delete_workshop', as: :delete_workshop, via: :all
          post 'comment' => 'workshops#add_comment', as: :workshop_comment
          post 'toggle-interest' => 'workshops#toggle_workshop_interest', as: :toggle_workshop_interest
          match 'translate/:locale' => 'workshops#translate_workshop', as: :translate_workshop, via: :all

          scope :facilitate do
            root 'workshops#facilitate_workshop', as: :facilitate_workshop
            get 'sent' => 'workshops#sent_facilitate_request', as: :sent_facilitate_workshop
          end

          post 'add_facilitator' => 'workshops#add_workshop_facilitator', as: :workshop_add_facilitator
          
          scope :facilitate_request do
            root 'workshops#facilitate_request', as: :facilitate_workshop_request, via: :post

            get ':user_id/:approve_or_deny' => 'workshops#approve_facilitate_request', as: :approve_facilitate_workshop_request
          end
        end
      end
    end
  end

  # Contact
  scope :contact do
    root 'application#contact', as: :contact

    post 'send' => 'application#contact_send', as: :contact_send
    get 'sent' => 'application#contact_sent', as: :contact_sent
  end

  # Static pages
  get 'about' => 'application#about', as: :about
  get 'policy' => 'application#policy', as: :policy

  # Site info
  get 'robots.txt' => 'application#robots', as: :robots_txt
  get 'humans.txt' => 'application#humans', as: :humans_txt

  # Error pages
  match 'js_error' => 'application#js_error', via: :all
  get 'error_403' => 'application#do_403' unless Rails.env.production?
  get 'error_404' => 'application#error_404' unless Rails.env.production?
  get 'error_500' => 'application#error_500' unless Rails.env.production?
  get 'locale_not_available_error/:locale' => 'application#locale_not_available' unless Rails.env.production?

  # Home page
  root 'application#home', as: :home

end
