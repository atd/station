module CMS
  module Controller
    # Authorization module provides your Controllers and Views with methods and filters
    # to control the actions of Agents
    #
    # This module uses Agent identification support from CMS::Controller::Authentication
    #
    # Filters are defined in the following way:
    #   authorization_filter container, actions, options
    #
    module Authorization
      # Inclusion hook to add CMS::Controller::Authentication
      def self.included(base) #:nodoc:
        base.send :include, CMS::Controller::Authentication unless base.instance_methods.include?('authenticated?')

        base.helper_method :authorization?
        class << base
          # Calls not_authorized unless container allows current_agent to perform actions
          def authorization_filter(container, actions, options)
            before_filter options do |controller|
              controller.not_authorized unless controller.authorization?(container, actions)
            end
          end
        end
      end

      # Is current_agent authorized to perform all actions in container variable?
      def authorization?(container, actions)
        container = self.instance_variable_get("@#{ container }")
        container.authorizes?(current_agent, actions)
      end

      # Set HTTP Forbidden (403) response for actions not authorized
      def not_authorized
        respond_to do |format|
          format.html do
            render :file => "#{RAILS_ROOT}/public/403.html", 
                   :status => 403
          end
          
          for mime in CMS.mime_types
            format.send mime.to_sym do
              render :text => 'Forbidden',
                     :status => 403
            end
          end
        end
      end
    end
  end
end
