module CMS
  module ActionController
    # Controller methods and default filters for Agents Controllers
    module Agents
      class << self
        def included(base) #:nodoc:
          base.send :include, CMS::ActionController::Base unless base.ancestors.include?(CMS::ActionController::Base)
          base.send :include, CMS::ActionController::Authentication unless base.ancestors.include?(CMS::ActionController::Authentication)
        end
      end

      # Show agent
      #
      # Responds to Atom Service format, returning the Containers this Agent can post to
      def show
        @containers = @agent.stages.select{ |s| s.authorizes?(current_agent, :read) }.sort{ |x, y| x.name <=> y.name }
        @agents = @agent.fellows

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
        @agent = self.resource_class.new
        instance_variable_set "@#{ self.resource_class.to_s.underscore }", @agent
        @title = authenticated? ?
          t(:new, :scope => self.resource_class.to_s.underscore) :
          t(:join_to_site, :site => Site.current.name)
      end
    
      # Create new Agent instance
      def create
        @agent = self.resource_class.new(params[:agent])

        unless authenticated?
          cookies.delete :auth_token unless authenticated?
          @agent.openid_identifier = session[:openid_identifier]
        end

        @agent.save!

        if authenticated?
          redirect_to polymorphic_path(self.resource_class.new)
          flash[:info] = t(:created, :scope => @agent.class.to_s.underscore)
        else
          self.current_agent = @agent
          redirect_to @agent
          flash[:info] = t(:account_created)
        end

	if self.resource_class.agent_options[:activation]
	  flash[:info] << '<br />'
          flash[:info] << ( @agent.active? ?
            t(:activation_email_sent, :scope => @agent.class.to_s.underscore) :
            t(:should_check_email_to_activate_account))
	end
      rescue ::ActiveRecord::RecordInvalid
        render :action => 'new'
      end

      def destroy
        @agent.destroy
        flash[:info] = t(:deleted, :scope => @agent.class.to_s.underscore)
        redirect_to polymorphic_path(self.resource_class.new)
      end
    
      # Activate Agent from email
      def activate
        self.current_agent = params[:activation_code].blank? ? Anonymous.current : self.resource_class.find_by_activation_code(params[:activation_code])
        if authenticated? && current_agent.respond_to?("active?") && !current_agent.active?
          current_agent.activate
          flash[:info] = t(:account_activated)
        end

        redirect_back_or_default(after_activate_path)
      end
    
      def forgot_password
        if params[:email]
          @agent = self.resource_class.find_by_email(params[:email])
          unless @agent
            flash[:error] = t(:could_not_find_anybody_with_that_email_address)
            return
          end
    
          @agent.forgot_password
          flash[:info] = t(:password_reset_link_sent_to_email_address)
          redirect_to("/")
        end
      end
    
      # Resets Agent password via email
      def reset_password
        @agent = self.resource_class.find_by_reset_password_code(params[:reset_password_code])
        raise unless @agent
        return if params[:password].blank?
        
        @agent.update_attributes(:password => params[:password], 
                                 :password_confirmation => params[:password_confirmation])
        if @agent.valid?
          @agent.reset_password
          current_agent = @agent
          flash[:info] = t(:password_has_been_reset)
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
        @agent = ( params[:id].match(/^\d+$/) ? self.resource_class.find(params[:id]) : self.resource_class.find_by_login(params[:id]) )
        instance_variable_set "@#{ self.resource_class.to_s.underscore }", @agent
      end
    
      # Filter for activation methods
      def activation_required
        redirect_back_or_default('/') unless self.resource_class.agent_options[:activation]
      end
    
      # Filter for methods that require login_and_password authentication, like reset_password
      def login_and_pass_auth_required
        redirect_back_or_default('/') unless self.resource_class.agent_options[:authentication].include?(:login_and_password)
      end

      private

      def after_activate_path
        '/'
      end
    end
  end
end
