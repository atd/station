# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  include CMS::Controller::Sessions

  # render new.rhtml
  def new
    authentication_methods.each do |method|
      send "new_with_#{ method }" if respond_to? "new_with_#{ method }"
      break if performed?
    end
  end

  def create
    authentication_methods.each do |method|
      send "create_with_#{ method }" if respond_to? "create_with_#{ method }"
      break if performed?
    end
  end

  def destroy
    self.current_agent.forget_me if authenticated? &&
      current_agent.agent_options[:authentication].include?(:cookie_token)
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out.".t
    redirect_back_or_default(after_destroy_path)
  end

  private

  # Array of Authentication methods used in this controller
  def authentication_methods
    CMS::Agent.authentication_methods
  end

  def after_create_path
    '/'
  end

  def after_destroy_path
    '/'
  end
end
