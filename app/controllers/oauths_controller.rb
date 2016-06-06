class OauthsController < ApplicationController
  skip_before_filter :require_login

  # sends the user on a trip to the provider,
  # and after authorizing there back to the callback url.
  def oauth
    set_callback
    session[:oauth_last_url] = request.referer
    login_at(auth_params[:provider])
  end

  def callback
    set_callback

    user_info = (sorcery_fetch_user_hash auth_params[:provider] || {})[:user_info]
    user = User.find_by_email(user_info['email'])
    
    # create the user if the email is not recognized
    unless user
      user = User.new(email: user_info['email'], firstname: user_info['name'])
      user.save!
    end
    
    # log in the user
    auto_login(user) if user
    
    redirect_to (session[:oauth_last_url] || home_path)
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