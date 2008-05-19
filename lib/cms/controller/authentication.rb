module CMS
  module Controller
    # Authentication module provides with Controller and Helper methods 
    # for Agent identification support
    #
    # For permissions issues in your Controllers, see CMS::Controller::Authorization
    #
    # == Current Agent
    # There are some methods available to access the Agent
    # that is requesting some action
    #  
    # authenticated?:: Is there any Agent authenticated in this request?
    # current_agent::  Agent currently authenticated. Defaults to <tt>:false</tt>
    # current_agent=::  Set current_agent
    #
    # You can also use the name of a model that acts_as_agent
    #   def User
    #     acts_as_agent
    #   end
    #
    #   current_user # => The authenticated user, or :false
    #
    # == Filters
    # authentication_required:: The action requires to be performed by an 
    #                           authenticated Agent. Calls access_denied 
    #                           if there is none
    #
    # == State Information
    # Authentication state information can be obtained from these sources
    #
    # HTTP Basic auth:: HTTP headers
    # Session:: Rails Session[http://api.rubyonrails.org/classes/ActionController/Integration/Session.html]
    # Cookie::  CMS::Agent::Remember
    #
    module Authentication
      # Inclusion hook to make #current_agent and #authenticated? methods
      # available as ActionView helper methods.
      def self.included(base) # :nodoc:
        base.send :helper_method, :current_agent, :authenticated?, :logged_in?

        # Add "current_#{ agent_type}" methods..
        current_polymorphic_agent_proc = lambda do
          alias_method_chain :method_missing, :current_polymorphic_agent
        end

        # ..in the Controller
        base.class_eval &current_polymorphic_agent_proc

        # ..in the Helper
        base.helper_method :method_missing_with_current_polymorphic_agent
        base.master_helper_module.module_eval &current_polymorphic_agent_proc
      end
  
      protected
        # Returns true or false if an Agent is authenticated
        # Preloads @current_agent with the Agent's model if they're authenticated
        def authenticated?
          current_agent != :false
        end
  
        # Compativility with restful_authentication plugin
        alias logged_in? authenticated?
  
        # Hook for CMS.agents based current_#{ agent_class } methods
        # This allows using current_#{ agent_class } in controllers and helpers
        def method_missing_with_current_polymorphic_agent(method, *args, &block) #:nodoc:
          if method.to_s =~ /^current_(.*)$/
            agent = $1
            if CMS.agents.include?(agent.pluralize.to_sym)
              return current_polymorphic_agent(agent.classify.constantize)
            end
          end
          method_missing_without_current_polymorphic_agent(method, *args, &block)
        end
  
        # Accesses the current Agent from the session.  Set it to :false if authentication
        # fails so that future calls do not hit the database.
        def current_agent
          @current_agent ||= (login_from_session || login_from_basic_auth || login_from_cookie || :false)
        end
  
        def current_polymorphic_agent(agent_klass) #:nodoc:
          current_agent.is_a?(agent_klass) ? current_agent : :false
        end
  
        # Store the given agent id and agent_type in the session.
        def current_agent=(new_agent)
          if new_agent.nil? || new_agent.is_a?(Symbol)
            session[:agent_id] = session[:agent_type] = nil
          else
            session[:agent_id]   = new_agent.id
            session[:agent_type] = new_agent.class.to_s
          end
          @current_agent = new_agent || :false
        end
  
        # Filter method to enforce an authentication requirement.
        #
        # To require authentication for all actions, use this in your controllers:
        #
        #   before_filter :authentication_required
        #
        # To require authentication for specific actions, use this in your controllers:
        #
        #   before_filter :authentication_required, :only => [ :edit, :update ]
        #
        # To skip this in a subclassed controller:
        #
        #   skip_before_filter :authentication_required
        #
        def authentication_required
          authenticated? || access_denied
        end
  
        # Redirect as appropriate when an access request fails.
        #
        # The default action is to redirect to the login screen if responding to HTML
        # For other types of contents, send 401 Unauthorized
        # TODO? send 401 in HTML also
        #
        # Override this method in your controllers if you want to have special
        # behavior in case the Agent is not authorized
        # to access the requested action.  For example, a popup window might
        # simply close itself.
        def access_denied
          respond_to do |format|
            format.html do
              store_location
              redirect_to new_session_path
            end
  
            for mime in CMS.mime_types
              format.send mime.to_sym do
                request_http_basic_authentication 'Web Password'
              end
            end
          end
        end
  
        # Store the URI of the current request in the session.
        #
        # We can return to this location by calling #redirect_back_or_default.
        def store_location
          session[:return_to] = request.request_uri
        end
  
        # Redirect to the URI stored by the most recent store_location call or
        # to the passed default.
        def redirect_back_or_default(default)
          redirect_to(session[:return_to] || default)
          session[:return_to] = nil
        end
  
  
	# Attempt to login by the agent id and type stored in the session.
        def login_from_session #:nodoc:
          if session[:agent_id] && session[:agent_type] && CMS.agents.include?(session[:agent_type].tableize.to_sym)
            self.current_agent = session[:agent_type].constantize.find(session[:agent_id])
          end
        end
  
        # Attempt to authenticate by basic authentication information.
        def login_from_basic_auth #:nodoc:
          authenticate_with_http_basic do |username, password|
            for klass in CMS.agent_classes
              if klass.agent_options[:authentication].include?(:login_and_password)
                agent = klass.authenticate_with_login_and_password(username, password)
                return (self.current_agent = agent) if agent
              end
            end
          end
          nil
        end
  
        # Attempt to authenticate by an expiring token in the cookie.
        def login_from_cookie #:nodoc:
          CMS.agent_classes.each do |agent_class|
            agent = agent_class.find_by_remember_token(cookies[:auth_token])
            if agent && agent.remember_token?
              agent.remember_me
              cookies[:auth_token] = { :value =>   agent.remember_token, 
                                       :expires => agent.remember_token_expires_at }
              return self.current_agent = agent
            end
          end if cookies[:auth_token]
          nil
        end
    end
  end
end
