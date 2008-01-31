# This controller handles the login/logout function of the site.  
class <%= controller_class_name %>Controller < ApplicationController
  # Be sure to include CMS::Authentication in Application Controller instead
  include CMS::Authentication

  # render new.rhtml
  def new
  end

  def create
    self.current_agent = <%= class_name %>.authenticate(params[:login], params[:password])
    if authenticated?
      if params[:remember_me] == "1"
        self.current_agent.remember_me
        cookies[:auth_token] = { :value => self.current_agent.remember_token , :expires => self.current_agent.remember_token_expires_at }
      end
      redirect_back_or_default('/')
      flash[:notice] = "Logged in successfully"
    else
      render :action => 'new'
    end
  end

  def destroy
    self.current_agent.forget_me if authenticated?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end
end
