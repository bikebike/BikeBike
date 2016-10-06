class OauthsController < ApplicationController
  skip_before_filter :require_login

  # sends the user on a trip to the provider,
  # and after authorizing there back to the callback url.
  def oauth
    set_callback
    session[:oauth_last_url] = params[:dest] || request.referer
    login_at(auth_params[:provider])
  end

  def callback
    set_callback

    user_info = (sorcery_fetch_user_hash auth_params[:provider] || {})[:user_info]

    email = user_info['email']
    fb_id = user_info['id']

    # try to find the user by facebook id
    user = User.find_by_fb_id(fb_id)

    # otherwise find the user by email
    unless user.present?
      # only look if the email address is present
      user = User.find_by_email(email) if email.present?
    end

    # create the user if the email is not recognized
    if user.nil?
      if email.present?
        user = User.new(email: email, firstname: user_info['name'], fb_id: fb_id)
        user.save!
      else
        session[:oauth_update_user_info] = user_info
        return redirect_to oauth_update_path
      end
    elsif user.fb_id.blank? || user.email.blank?
      user.email = email
      user.fb_id = fb_id
      user.save!
    end
    
    if user.present? && user.email.present?
      # log in the user
      auto_login(user)
    end
    
    oauth_last_url = (session[:oauth_last_url] || home_path)
    session.delete(:oauth_last_url)
    redirect_to oauth_last_url
  end

  def update
    @main_title = @page_title = 'articles.conference_registration.headings.email_confirm'
    @errors = { email: flash[:error] } if flash[:error].present?
    render 'application/update_user'
  end
  
  def save
    unless params[:email].present?
      return redirect_to oauth_update_path
    end
    
    user = User.find_by_email(params[:email])

    if user.present?
      flash[:error] = :exists
      return redirect_to oauth_update_path
    end
    
    # create the user
    user = User.new(email: params[:email], firstname: session[:oauth_update_user_info]['name'], fb_id: session[:oauth_update_user_info]['id'])
    user.save!

    # log in
    auto_login(user)

    # clear out the session
    oauth_last_url = (session[:oauth_last_url] || home_path)
    session.delete(:oauth_last_url)
    session.delete(:oauth_update_user_info)

    # go to our final destination
    redirect_to oauth_last_url
  end

  private
  def auth_params
    params.permit(:code, :provider)
  end

  def set_callback
    # force https for prod
    protocol = Rails.env.preview? || Rails.env.production? ? 'https://' : request.protocol

    # build the callback url
    Sorcery::Controller::Config.send(params[:provider]).callback_url =
        "#{protocol}#{request.env['HTTP_HOST']}/oauth/callback?provider=facebook"
  end

end