module ActiveRecord #:nodoc:
  # Authorization module provide ActiveRecord models with authorization features.
  #
  #
  # Include Authorization functionality in your models using ActsAsMethods#
  module Authorization
    class << self
      def included(base) #:nodoc:
        base.extend ClassMethods
        base.send :include, InstanceMethods
      end
    end

    module ClassMethods
      def authorization_methods
        @authorization_methods ||= []
      end

      protected

      # Define new authorization method
      #
      # ToDoc
      def authorizing(method = nil, &block)
        @authorization_methods = authorization_methods | Array(method || block)
      end
    end

    # Instance methods can be redefined in each Model for custom features
    module InstanceMethods
      # There is authorization if there are any affordances that match the action
      #
      # action can be:
      # ActiveRecord::Authorization::Agent instance
      # Symbol or String:: describes the action name. Objective will be nil
      #   resource.authorize?(:update, :to => user)
      # Array:: pair of action_name, :objective
      #   resource.authorize?([ :create, :attachment ], :to => user)
      #
      # Options:
      # to:: Agent of the Affordance. Defaults to Anyone
      #
      def authorize?(permission, options = {})
        agent = options[:to] || Anonymous.current
        cached_auth = agent.cached_authorized?(self, permission)
        if cached_auth.present?
          cached_auth
        else
          val = authorization_methods_chain(agent, permission)
          agent.add_cached_authorization(self, permission, val)
          val
        end    
      end

      #FIXME: DRY:
      def authorizes?(permission, options = {})
        logger.debug "Station: DEPRECATION WARNING \"authorizes?\". Please use \"authorize?\" instead."
        line = caller.select{ |l| l =~ /^#{ RAILS_ROOT }/ }.first
        logger.debug "           in: #{ line }"

        authorize?(permission, options)
      end
      
      def authorization_methods_chain(agent, permission)
        
        self.class.authorization_methods.each do |m|
          case m
          when Symbol
            return true if send(m, agent, permission)
          when Proc
            return true if m.bind(self).call(agent, permission)
          else
            raise "Invalid Authorization method #{ m }"
          end
        end

        false
      end
    end
  end
end
