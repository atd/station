# Controller for Agents management
class CMS::AgentsController < ApplicationController
  include CMS::Authentication

  before_filter :get_agent, :only => :show
  before_filter :activation_required, :only => [ :activate, 
                                                 :forgot_password, 
                                                 :reset_password ]
  before_filter :login_and_pass_auth_required, :only => [ :forgot_password,
                                                          :reset_password ]

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
    @agent = agent_class.new
  end

  # Create new Agent instance
  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @agent = agent_class.new(params[:agent])
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
    self.current_agent = params[:activation_code].blank? ? :false : agent_class.find_by_activation_code(params[:activation_code])
    if authenticated? && current_agent.respond_to?("active?") && !current_agent.active?
      current_agent.activate
      flash[:notice] = "Signup complete!"
    end
    redirect_back_or_default('/')
  end

  def forgot_password
    if params[:email]
      @agent = agent_class.find_by_email(params[:email])
      unless @agent
        flash[:error] = "Could not find anybody with that email address"
        return
      end

      @agent.forgot_password
      flash[:notice] = "A password reset link has been sent to email address"
      redirect_to("/")
    end
  end

  # Resets Agent password via email
  def reset_password
    @agent = agent_class.find_by_reset_password_code(params[:reset_password_code])
    raise unless @agent
    return unless params[:password]
    
    @agent.update_attributes(:password => params[:password], 
                             :password_confirmation => params[:password_confirmation])
    if @agent.valid?
      @agent.reset_password
      current_agent = @agent
      flash[:notice] = "Password reset"
      redirect_to("/")
    end

    rescue
      flash[:notice] = "Invalid reset code. Please, check the link and try again. (Tip: Did your email client break the link?)"
      redirect_to("/")
  end

  protected

  # Get Agent filter
  # Gets Agent instance by id or login
  #
  # Example GET /users/1 or GET /users/quentin
  def get_agent
    @agent = ( params[:id].match(/\d+/) ? agent_class.find(params[:id]) : agent_class.find_by_login(params[:id]) )
  end

  # Filter for 
  def activation_required
    redirect_back_or_default('/') unless agent_class.agent_options[:activation]
  end

  def login_and_pass_auth_required
    redirect_back_or_default('/') unless agent_class.agent_options[:authentication].include?(:login_and_password)
  end

  private

  # Returns the model class related with this controller
  #
  # Useful for controllers that inherit this class
  def agent_class # :nodoc:
    @agent_class ||= controller_name.classify.constantize
  end
end
