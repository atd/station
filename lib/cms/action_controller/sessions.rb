module CMS
  module ActionController
    # Sessions module provides with Controller and Helper methods 
    # for sessions management
    #
    # This methods will be tipically used by SessionsController
    #
    # For identification issues in your Controllers, see CMS::ActionController::Authorization
    # For permissions issues in your Controllers, see CMS::ActionController::Authorization
    #
    module Sessions
      class << self
        def included(base) # :nodoc:
          base.send :include, CMS::ActionController::Authentication unless base.ancestors.include?(CMS::ActionController::Authentication)

          CMS::ActiveRecord::Agent.authentication_methods.each do |method|
            mod = "CMS::ActionController::Sessions::#{ method.to_s.classify }".constantize
            base.send :include, mod
          end
        end
      end

      # Go through all authentication methods definded for this action
      # Return is one of them is performed
      def authentication_methods_chain(controller_method_name)
        authentication_methods.each do |authentication_method|
          chain_method = "#{ controller_method_name }_with_#{ authentication_method }"
          send(chain_method) if respond_to?(chain_method)
          break if performed?
        end
      end

      private

      # Array of Authentication methods used in this controller
      def authentication_methods
        CMS::ActiveRecord::Agent.authentication_methods
      end
    end
  end
end
