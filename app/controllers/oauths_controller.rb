class OauthsController < ApplicationController
  skip_before_filter :require_login

  # sends the user on a trip to the provider,
  # and after authorizing there back to the callback url.
  def oauth
    session[:oauth_last_url] = request.referer
    login_at(auth_params[:provider])
  end

  def callback
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
    #, :notice => "Logged in with #{provider.titleize}!"
    # if @user = login_from(provider)
    # else
    #   begin
    #     @user = create_from(auth_params[:provider])

    #     reset_session
    #     auto_login(@user)
    #     redirect_to redirect_url, :notice => "Signed up with #{provider.titleize}!"
    #   rescue
    #     redirect_to redirect_url, :alert => "Failed to login with #{provider.titleize}!"
    #   end
    # end
  end

  private
  def auth_params
    params.permit(:code, :provider)
  end

end