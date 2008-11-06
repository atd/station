module CMS
  module ActionController
    # Authorization module provides your Controllers and Views with methods and filters
    # to control the actions of Agents
    #
    # This module uses Agent identification support from CMS::ActionController::Authentication
    #
    # == Authorization Filters
    # You can define authorization filters in the following way:
    #   authorization_filter stage, permission, options
    #
    # stage:: the instance variable of the controller that will respond to <tt>authorizes?(current_agent, permission)</tt>
    # permission:: Array with a pair of <tt>[ :action, :objective ]</tt>. Objective must be the symbol of a class (<tt>:User</tt>) or <tt>:self</tt>
    # options:: Hash of options passed to before_filter
    #
    # === Examples
    #
    #  class AttachmentsController < ActionController::Base
    #    before_filter :get_space, :only => [ :index, :new, :create ]
    #
    #    authorization_filter :space, [ :read, :Attachment ], :only => [ :index ]
    #    authorization_filter :space, [ :create, :Attachment ], :only => [ :new, :create ]
    #
    #    before_filter :get_attachment, :only => [ :show, :edit, :update, :destroy ]
    #
    #    authorization_filter :attachment, [ :read, :self ], :only => [ :show ]
    #    authorization_filter :attachment, [ :update, :self ], :only => [ :edit, :update ]
    #    authorization_filter :attachment, [ :delete, :self ], :only => [ :destroy ]
    #
    #  end
    module Authorization
      # Inclusion hook to add CMS::ActionController::Authentication
      def self.included(base) #:nodoc:
        base.send :include, CMS::ActionController::Authentication unless base.ancestors.include?(CMS::ActionController::Authentication)

        base.helper_method :authorized?
        class << base
          # Calls not_authorized unless stage allows current_agent to perform actions
          def authorization_filter(stage, actions, options)
            before_filter options do |controller|
              controller.not_authorized unless controller.authorized?(stage, actions)
            end
          end
        end
      end

      # Is current_agent authorized to perform all actions in stage?
      def authorized?(stage, actions)
        stage = self.instance_variable_get("@#{ stage }")
        stage.authorizes?(current_agent, actions)
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
