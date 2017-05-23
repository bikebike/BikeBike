class WorkshopsController < ApplicationController

  def workshops
    set_conference
    set_conference_registration!
    @workshops = Workshop.where(conference_id: @this_conference.id)
    @my_workshops = @workshops.select { |w| w.active_facilitator?(current_user) }
    render 'workshops/index'
  end

  def view_workshop
    set_conference
    set_conference_registration!
    @workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
    return do_404 unless @workshop

    @translations_available_for_editing = []
    I18n.backend.enabled_locales.each do |locale|
      @translations_available_for_editing << locale if @workshop.can_translate?(current_user, locale)
    end
    @page_title = 'page_titles.conferences.View_Workshop'
    @register_template = :workshops

    render 'workshops/show'
  end

  def create_workshop
    set_conference
    set_conference_registration!
    @workshop = Workshop.new
    @languages = [I18n.locale.to_sym]
    @needs = []
    @page_title = 'page_titles.conferences.Create_Workshop'
    @register_template = :workshops
    render 'workshops/new'
  end

  def translate_workshop
    @is_translating = true
    @translation = params[:locale]
    @page_title = 'page_titles.conferences.Translate_Workshop'
    @page_title_vars = { language: view_context.language_name(@translation) }
    @register_template = :workshops

    edit_workshop
  end

  def edit_workshop
    set_conference
    set_conference_registration!
    @workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
    
    return do_404 unless @workshop.present?

    @page_title ||= 'page_titles.conferences.Edit_Workshop'

    @can_edit = @workshop.can_edit?(current_user)

    @is_translating ||= false
    if @is_translating
      return do_404 unless @translation.to_s != @workshop.locale.to_s && LinguaFranca.locale_enabled?(@translation.to_sym)
      return do_403 unless @workshop.can_translate?(current_user, @translation)

      @title = @workshop._title(@translation)
      @info = @workshop._info(@translation)
    else
      return do_403 unless @can_edit

      @title = @workshop.title
      @info = @workshop.info
    end

    @needs = JSON.parse(@workshop.needs || '[]').map &:to_sym
    @languages = JSON.parse(@workshop.languages || '[]').map &:to_sym
    @space = @workshop.space.to_sym if @workshop.space
    @theme = @workshop.theme.to_sym if @workshop.theme
    @notes = @workshop.notes
    @register_template = :workshops

    render 'workshops/new'
  end

  def delete_workshop
    set_conference
    set_conference_registration!
    @workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)

    return do_404 unless @workshop.present?
    return do_403 unless @workshop.can_delete?(current_user)

    if request.post?
      if params[:button] == 'confirm'
        if @workshop
          @workshop.workshop_facilitators.destroy_all
          @workshop.destroy
        end

        return redirect_to register_step_path(@this_conference.slug, 'workshops')
      end
      return redirect_to view_workshop_url(@this_conference.slug, @workshop.id)
    end
    @register_template = :workshops

    render 'workshops/delete'
  end
  
  def save_workshop
    set_conference
    set_conference_registration!

    if params[:button].to_sym != :save
      if params[:workshop_id].present?
        return redirect_to view_workshop_url(@this_conference.slug, params[:workshop_id])
      end
      return redirect_to register_step_path(@this_conference.slug, 'workshops')
    end

    if params[:workshop_id].present?
      workshop = Workshop.find(params[:workshop_id])
      return do_404 unless workshop.present?
      can_edit = workshop.can_edit?(current_user)
    else
      workshop = Workshop.new(:conference_id => @this_conference.id)
      workshop.workshop_facilitators = [WorkshopFacilitator.new(:user_id => current_user.id, :role => :creator)]
      can_edit = true
    end

    title = params[:title]
    info  = params[:info].gsub(/^\s*(.*?)\s*$/, '\1')

    if params[:translation].present? && workshop.can_translate?(current_user, params[:translation])
      old_title = workshop._title(params[:translation])
      old_info = workshop._info(params[:translation])

      do_save = false

      unless title == old_title
        workshop.set_column_for_locale(:title, params[:translation], title, current_user.id)
        do_save = true
      end
      unless info == old_info
        workshop.set_column_for_locale(:info, params[:translation], info, current_user.id)
        do_save = true
      end
      
      # only save if the text has changed, if we want to make sure only to update the translator id if necessary
      workshop.save_translations if do_save
    elsif can_edit
      workshop.title              = title
      workshop.info               = info
      workshop.languages          = (params[:languages] || {}).keys.to_json
      workshop.needs              = (params[:needs] || {}).keys.to_json
      workshop.theme              = params[:theme] == 'other' ? params[:other_theme] : params[:theme]
      workshop.space              = params[:space]
      workshop.notes              = params[:notes]
      workshop.needs_facilitators = params[:needs_facilitators].present?
      workshop.save

      # Rouge nil facilitators have been know to be created, just destroy them here now
      WorkshopFacilitator.where(:user_id => nil).destroy_all
    else
      return do_403
    end

    redirect_to view_workshop_url(@this_conference.slug, workshop.id)
  end

  def toggle_workshop_interest
    set_conference
    set_conference_registration!
    workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
    return do_404 unless workshop

    # save the current state
    interested = workshop.interested? current_user
    # remove all associated fields
    WorkshopInterest.delete_all(:workshop_id => workshop.id, :user_id => current_user.id)

    # creat the new interest row if we weren't interested before
    WorkshopInterest.create(:workshop_id => workshop.id, :user_id => current_user.id) unless interested

    if request.xhr?
      render json: [
        {
          selector: '.interest-button',
          html: view_context.interest_button(workshop)
        },
        {
          selector: '.interest-text',
          html: view_context.interest_text(workshop)
        }
      ]
    else
      # go back to the workshop
      redirect_to view_workshop_url(@this_conference.slug, workshop.id)
    end
  end

  def facilitate_workshop
    set_conference
    set_conference_registration!
    @workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
    return do_404 unless @workshop
    return do_403 if @workshop.facilitator?(current_user) || !current_user

    @register_template = :workshops
    render 'workshops/facilitate'
  end

  def facilitate_request
    set_conference
    set_conference_registration!
    workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
    return do_404 unless workshop
    return do_403 if workshop.facilitator?(current_user) || !current_user

    # create the request by making the user a facilitator but making their role 'requested'
    WorkshopFacilitator.create(user_id: current_user.id, workshop_id: workshop.id, role: :requested)

    send_mail(:workshop_facilitator_request, workshop.id, current_user.id, params[:message])

    redirect_to sent_facilitate_workshop_url(@this_conference.slug, workshop.id)
  end

  def sent_facilitate_request
    set_conference
    set_conference_registration!
    @workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
    return do_404 unless @workshop
    return do_403 unless @workshop.requested_collaborator?(current_user)

    @register_template = :workshops
    render 'workshops/facilitate_request_sent'
  end

  def approve_facilitate_request
    return do_403 unless logged_in?
    set_conference
    set_conference_registration!
    workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
    return do_404 unless workshop.present?
    
    user_id = params[:user_id].to_i
    action = params[:approve_or_deny].to_sym
    user = User.find(user_id)
    case action
    when :approve
      if workshop.active_facilitator?(current_user) && workshop.requested_collaborator?(User.find(user_id))
        f = WorkshopFacilitator.find_by_workshop_id_and_user_id(
            workshop.id, user_id)
        f.role = :collaborator
        f.save
        LinguaFranca.with_locale(user.locale) do
          send_mail(:workshop_facilitator_request_approved, workshop.id, user.id)
        end
        return redirect_to view_workshop_url(@this_conference.slug, workshop.id)
      end
    when :deny
      if workshop.active_facilitator?(current_user) && workshop.requested_collaborator?(User.find(user_id))
        WorkshopFacilitator.delete_all(
          :workshop_id => workshop.id,
          :user_id => user_id)
        LinguaFranca.with_locale user.locale do
          send_mail(:workshop_facilitator_request_denied, workshop.id, user.id)
        end
        return redirect_to view_workshop_url(@this_conference.slug, workshop.id)    
      end
    when :remove
      if workshop.can_remove?(current_user, user)
        WorkshopFacilitator.delete_all(
          :workshop_id => workshop.id,
          :user_id => user_id)
        return redirect_to view_workshop_url(@this_conference.slug, workshop.id)
      end
    when :switch_ownership
      if workshop.creator?(current_user)
        f = WorkshopFacilitator.find_by_workshop_id_and_user_id(
            workshop.id, current_user.id)
        f.role = :collaborator
        f.save
        f = WorkshopFacilitator.find_by_workshop_id_and_user_id(
            workshop.id, user_id)
        f.role = :creator
        f.save
        return redirect_to view_workshop_url(@this_conference.slug, workshop.id)
      end
    end

    return do_403
  end

  def add_workshop_facilitator
    set_conference
    set_conference_registration!

    user = User.find_user(params[:email])

    # create the user if they don't exist and send them a link to register
    unless user
      user = User.create(email: params[:email], locale: I18n.locale)
      generate_confirmation(user, register_path(@this_conference.slug))
    end

    workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)

    return do_404 unless workshop && current_user

    unless workshop.facilitator?(user)
      WorkshopFacilitator.create(user_id: user.id, workshop_id: workshop.id, role: :collaborator)
      
      LinguaFranca.with_locale user.locale do
        send_mail(:workshop_facilitator_request_approved, workshop.id, user.id)
      end
    end

    return redirect_to view_workshop_url(@this_conference.slug, params[:workshop_id])
  end

  def add_comment
    set_conference
    set_conference_registration!
    workshop = Workshop.find_by_id_and_conference_id(params[:workshop_id], @this_conference.id)
    
    return do_404 unless workshop && current_user

    if params[:button] == 'reply'
      comment = Comment.find_by!(id: params[:comment_id].to_i, model_type: :workshops, model_id: workshop.id)
      new_comment = comment.add_comment(current_user, params[:reply])

      unless comment.user.id == current_user.id
        LinguaFranca.with_locale comment.user.locale do
          send_mail(:workshop_comment, workshop.id, new_comment.id, comment.user.id)
        end
      end
    elsif params[:button] = 'add_comment'
      new_comment = workshop.add_comment(current_user, params[:comment])

      workshop.active_facilitators.each do | u |
        unless u.id == current_user.id
          LinguaFranca.with_locale u.locale do
            send_mail(:workshop_comment, workshop.id, new_comment.id, u.id)
          end
        end
      end
    else
      return do_404
    end

    return redirect_to view_workshop_url(@this_conference.slug, workshop.id, anchor: "comment-#{new_comment.id}")
  end

  rescue_from ActiveRecord::PremissionDenied do |exception|
    if !@this_conference.can_register?
      do_404
    elsif logged_in?
      redirect_to 'conferences/register'
    else
      @register_template = :confirm_email
      @page_title = "articles.conference_registration.headings.#{@this_conference.registration_status == :open ? '': 'Pre_'}Registration_Details"
      @main_title = "articles.conference_registration.headings.#{@this_conference.registration_status == :open ? '': 'Pre_'}Register"
      @main_title_vars = { vars: { title: @this_conference.title } }
      render 'conferences/register'
    end
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    do_404
  end

end
