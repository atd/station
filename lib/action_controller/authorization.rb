module ActionController #:nodoc:
  # Authorization module provides your Controllers and Views with methods and filters
  # to control the actions of Agents
  #
  # This module uses Agent identification support from ActionController::Authentication
  #
  # == Authorization Filters
  # You can define authorization filters in the following way:
  #   authorization_filter auth_action, auth_object, filter_options
  #
  # auth_action:: Argument defining the Permission. It's passed to @@auth_object.authorizes?@. See ActiveRecord::Stage#authorizes? method.
  # auth_object:: the instance variable of the controller that will respond to <tt>authorizes?(auth_action, :to => current_agent)</tt>
  # options:: Available options are:
  #   if:: A Proc proc{ |controller| ... } or Symbol to be executed as condition of the filter
  #   
  #  The rest of options are passed to before_filter. See Rails before_filter documentation
  #   
  #
  # === Examples
  #
  #  class AttachmentsController < ActionController::Base
  #    authorization_filter [ :read, :Attachment ], :space, { :only => [ :index ] }
  #    authorization_filter [ :create, :Attachment ], :space, { :only => [ :new, :create ] }
  #
  #    authorization_filter :read, :attachment, :only => [ :show ]
  #    authorization_filter :update, :attachment, :only => [ :edit, :update ]
  #    authorization_filter :delete, :attachment, :only => [ :destroy ]
  #
  #  end
  module Authorization
    # Inclusion hook to add ActionController::Authentication
    def self.included(base) #:nodoc:
      base.send :include, ActionController::Authentication unless base.ancestors.include?(ActionController::Authentication)

      base.helper_method :authorized?
      class << base
        # Calls not_authorized unless stage allows current_agent to perform actions
        def authorization_filter(auth_action, auth_object, options = {})
          if_condition = options.delete(:if)
          filter_condition = case if_condition
                             when Proc
                               if_condition
                             when Symbol
                               proc{ |controller| controller.send(if_condition) }
                             else
                               proc{ |controller| true }
                             end

          before_filter options do |controller|
            if filter_condition.call(controller)
              controller.not_authorized unless controller.authorized?(auth_action, auth_object)
            end
          end
        end
      end
    end

    # Is current_agent authorized to perform auth_action over auth_object?
    #
    # auth_action:: defined in ActiveRecord::Stage#authorizes?
    # auth_object_name:: if it's a Symbol, the name of an instance variable,
      # or the name of a method that returns the Stage asked auth_action. If
      # it's in nil, Site.current
    def authorized?(auth_action, auth_object_name)
      auth_object = if auth_object_name.is_a?(Symbol)
                      self.instance_variable_get("@#{ auth_object_name }") ||
                      send(auth_object_name)
                    else
                      auth_object_name || site
                    end

      auth_object.authorizes?(auth_action, :to => current_agent)
    end

    # If user is not authenticated, return not_authenticated to allow identification. 
    # Else, set HTTP Forbidden (403) response.
    def not_authorized
      return not_authenticated unless authenticated?

      respond_to do |format|
        format.all do
          render :text => 'Forbidden',
                 :status => 403
        end

        format.html do
          render(:file => "#{RAILS_ROOT}/public/403.html", 
                 :status => 403)
        end
      end
    end
  end
end
