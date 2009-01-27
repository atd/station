module CMS
  module ActionController
    # Authorization module provides your Controllers and Views with methods and filters
    # to control the actions of Agents
    #
    # This module uses Agent identification support from CMS::ActionController::Authentication
    #
    # == Authorization Filters
    # You can define authorization filters in the following way:
    #   authorization_filter auth_object, auth_argument, filter_options
    #
    # auth_object:: the instance variable of the controller that will respond to <tt>authorizes?(current_agent, auth_argument)</tt>
    # auth_argument:: Argument passed to @@auth_object.authorizes?@. See authorizes? methods
    # options:: Available options are:
    #   if:: A Proc proc{ |controller| ... } or Symbol to be executed as condition of the filter
    #   
    #  The rest of options are passed to before_filter. See Rails before_filter documentation
    #   
    #
    # === Examples
    #
    #  class AttachmentsController < ActionController::Base
    #    before_filter :get_space, :only => [ :index, :new, :create ]
    #
    #    authorization_filter :space, [ :read, :Attachment ], { :only => [ :index ] }
    #    authorization_filter :space, [ :create, :Attachment ], { :only => [ :new, :create ] }
    #
    #    before_filter :get_attachment, :only => [ :show, :edit, :update, :destroy ]
    #
    #    authorization_filter :attachment, :read, :only => [ :show ]
    #    authorization_filter :attachment, :update, :only => [ :edit, :update ]
    #    authorization_filter :attachment, :delete, :only => [ :destroy ]
    #
    #  end
    module Authorization
      # Inclusion hook to add CMS::ActionController::Authentication
      def self.included(base) #:nodoc:
        base.send :include, CMS::ActionController::Authentication unless base.ancestors.include?(CMS::ActionController::Authentication)

        base.helper_method :authorized?
        class << base
          # Calls not_authorized unless stage allows current_agent to perform actions
          def authorization_filter(auth_object, auth_argument, options = {})
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
                controller.not_authorized unless controller.authorized?(auth_object, auth_argument)
              end
            end
          end
        end
      end

      # Is current_agent authorized to perform auth_argument over auth_object?
      #
      # auth_object_name:: the name of an instance variable, or the name of a method
      #   that returns the Stage asked auth_argument
      # auth_argument:: defined in CMS::ActiveRecord::Stage#authorizes?
      def authorized?(auth_object_name, auth_argument)
        auth_object = self.instance_variable_get("@#{ auth_object_name }") ||
          send(auth_object_name)
        auth_object.authorizes?(current_agent, auth_argument)
      end

      # Set HTTP Forbidden (403) response for actions not authorized
      def not_authorized
        respond_to do |format|
          format.all do
            render :text => 'Forbidden',
                   :status => 403
          end

          format.html do
            render :file => "#{RAILS_ROOT}/public/403.html", 
                   :status => 403
          end
        end
      end
    end
  end
end
