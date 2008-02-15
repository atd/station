class CMS::AgentsController < ApplicationController
  include CMS::Authentication

  before_filter :set_agent_class

  # render new.rhtml
  def new
    @agent = @klass.new
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @agent = @klass.new(params[:agent])
    @agent.openid_identifier = session[:openid_identifier]
    @agent.save!
    @agent.openid_ownings.create(:uri => CMS::URI.find_or_create_by_uri(session[:openid_identifier])) if session[:openid_identifier]
    self.current_agent = @agent
    redirect_back_or_default('/')
    flash[:notice] = "Thanks for signing up!"
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end

  def activate
    return unless @klass.agent_options[:include_activation]

    self.current_agent = params[:activation_code].blank? ? :false : @klass.find_by_activation_code(params[:activation_code])
    if authenticated? && current_agent.respond_to("active?") && !current_agent.active?
      current_agent.activate
      flash[:notice] = "Signup complete!"
    end
    redirect_back_or_default('/')
  end

  private

  def set_agent_class # :nodoc:
    @klass = controller_name.classify.constantize
  end
end
