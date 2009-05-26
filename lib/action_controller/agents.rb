module ActionController #:nodoc:
  # Controller methods and default filters for Agents Controllers
  module Agents
    class << self
      def included(base) #:nodoc:
        base.send :include, ActionController::Move unless base.ancestors.include?(ActionController::Move)
        base.send :include, ActionController::Authentication unless base.ancestors.include?(ActionController::Authentication)
      end
    end

    def index
      # AtomPub feeds are ordered by Entry#updated_at
      # TODO: move this to ActionController::Base#params_parser
      if request.format == Mime::ATOM
        params[:order], params[:direction] = "updated_at", "DESC"
      end

      @resources = model_class.parents.in_container(container).column_sort(params[:order], params[:direction]).paginate(:page => params[:page])
      instance_variable_set "@#{ model_class.to_s.tableize }", @resources
      @agents = @resources

      respond_to do |format|
        format.html # index.html.erb
        format.js
        format.xml  { render :xml => @resources }
        format.atom
      end
    end

    # Show agent
    #
    # Responds to Atom Service format, returning the Containers this Agent can post to
    def show
      respond_to do |format|
        format.html {
          if @agent.agent_options[:openid_server]
            headers['X-XRDS-Location'] = formatted_polymorphic_url([ @agent, :xrds ])
            @openid_server_agent = @agent
          end
        }
        format.atomsvc
        format.xrds
      end
    end
  
    # Render a form for creating a new Agent
    def new
      @agent = model_class.new
      instance_variable_set "@#{ model_class.to_s.underscore }", @agent
      @title = authenticated? ?
        t(:new, :scope => model_class.to_s.underscore) :
        t(:join_to_site, :site => Site.current.name)
    end

    # Create new Agent instance
    def create
      @agent = model_class.new(params[:agent])

      unless authenticated?
        cookies.delete :auth_token
        @agent.openid_identifier = session[:openid_identifier]
      end

      @agent.save!

      if authenticated?
        redirect_to polymorphic_path(model_class.new)
        flash[:notice] = t(:created, :scope => @agent.class.to_s.underscore)
      else
        self.current_agent = @agent
        redirect_to @agent
        flash[:notice] = t(:account_created)
      end

      if model_class.agent_options[:activation]
        flash[:notice] << '<br />'
        flash[:notice] << ( @agent.active? ?
          t(:activation_email_sent, :scope => @agent.class.to_s.underscore) :
          t(:should_check_email_to_activate_account))
      end
    rescue ::ActiveRecord::RecordInvalid
      render :action => 'new'
    end

    def destroy
      @agent.destroy
      flash[:notice] = t(:deleted, :scope => @agent.class.to_s.underscore)
      redirect_to polymorphic_path(model_class.new)
    end
  
    # Activate Agent from email
    def activate
      self.current_agent = params[:activation_code].blank? ? Anonymous.current : model_class.find_by_activation_code(params[:activation_code])
      if authenticated? && current_agent.respond_to?("active?") && !current_agent.active?
        current_agent.activate
        flash[:success] = t(:account_activated)
        redirect_back_or_default(after_activate_path)
      else
        redirect_back_or_default(after_not_activate_path)
      end
    end
  
    def lost_password
      if params[:email]
        @agent = model_class.find_by_email(params[:email])
        unless @agent
          flash[:error] = t(:could_not_find_anybody_with_that_email_address)
          return
        end
  
        @agent.lost_password
        flash[:notice] = t(:password_reset_link_sent_to_email_address)
        redirect_to root_path
      end
    end
  
    # Resets Agent password via email
    def reset_password
      @agent = model_class.find_by_reset_password_code(params[:reset_password_code])
      raise unless @agent
      return if params[:password].blank?
      
      @agent.update_attributes(:password => params[:password], 
                               :password_confirmation => params[:password_confirmation])
      if @agent.valid?
        @agent.reset_password
        current_agent = @agent
        flash[:notice] = t(:password_has_been_reset)
        redirect_to("/")
      end
  
      rescue
        flash[:error] = t(:invalid_password_reset_code)
        redirect_to("/")
    end
  
    protected
  
    # Get Agent filter
    # Gets Agent instance by id or login
    #
    # Example GET /users/1 or GET /users/quentin
    def get_agent
      @agent = ( params[:id].match(/^\d+$/) ? model_class.find(params[:id]) : model_class.find_by_login(params[:id]) )
      instance_variable_set "@#{ model_class.to_s.underscore }", @agent
    end
  
    # Filter for activation methods
    def activation_required
      redirect_back_or_default('/') unless model_class.agent_options[:activation]
    end
  
    # Filter for methods that require login_and_password authentication, like reset_password
    def login_and_pass_auth_required
      redirect_back_or_default('/') unless model_class.agent_options[:authentication].include?(:login_and_password)
    end

    private

    def after_activate_path
      root_path
    end

    def after_not_activate_path
      root_path
    end
  end
end
