module CMS
  module Controller
    # Sessions module provides with Controller and Helper methods 
    # for sessions management
    #
    # For identification issues in your Controllers, see CMS::Controller::Authorization
    # For permissions issues in your Controllers, see CMS::Controller::Authorization
    #
    module Sessions
      def self.included(base) # :nodoc:
        base.send :include, CMS::Controller::Authentication unless base.ancestors.include?(CMS::Controller::Authentication)

        CMS::Agent.authentication_methods.each do |method|
          mod = "CMS::Controller::Sessions::#{ method.to_s.classify }".constantize
          base.send :include, mod
        end
      end
    end
  end
end
