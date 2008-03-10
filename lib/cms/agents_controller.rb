# Controller for Agents management
class CMS::AgentsController < ApplicationController
  include CMS::Authentication

  before_filter :set_agent_class
  before_filter :get_agent, :only => :show

  # Show agent
  #
  # Responds to Atom Service format, returning the Containers this Agent can post to
  def show
    respond_to do |format|
      format.html
      format.atomsvc {
        if @agent != current_agent
          access_denied
          return
        else
          render :layout => false
        end
      }
    end
  end

  # Render a form for creating a new Agent
  def new
    @agent = @klass.new
  end

  # Create new Agent instance
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

  # Activate Agent from email
  def activate
    unless @klass.agent_options[:activation]
      redirect_back_or_default('/')
      return 
    end

    self.current_agent = params[:activation_code].blank? ? :false : @klass.find_by_activation_code(params[:activation_code])
    if authenticated? && current_agent.respond_to?("active?") && !current_agent.active?
      current_agent.activate
      flash[:notice] = "Signup complete!"
    end
    redirect_back_or_default('/')
  end

  protected

  # Get Agent filter
  # Gets Agent instance by id or login
  #
  # Example GET /users/1 or GET /users/quentin
  def get_agent
    @agent = ( params[:id].match(/\d+/) ? @klass.find(params[:id]) : @klass.find_by_login(params[:id]) )
  end

  private

  # Set @klass variable to Agent class for this controller
  # Useful for controllers that inherit this class
  def set_agent_class # :nodoc:
    @klass = controller_name.classify.constantize
  end
end
