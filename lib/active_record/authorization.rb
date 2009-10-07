module ActiveRecord #:nodoc:
  # Authorization module provide ActiveRecord models with authorization features.
  #
  # Every ActiveRecord::Base descendant has an authorize? method.
  #
  # authorization_methods are defined using authorizing
  #
  # When asking for some permission, all the authorization_methods are
  # evaluated in sequence. Evaluation continues while the methods are returning nil.
  # When one of them returns true or false, this is the authorization result.
  #
  # By default, if there are no more methods, false is returned for the permission
  #
  module Authorization
    class << self
      def included(base) #:nodoc:
        base.extend ClassMethods
        base.send :include, InstanceMethods
      end
    end

    module ClassMethods
      # Available authorization methods for this class
      #
      def authorization_methods
        @authorization_methods ||= []
      end

      protected

      # Define a new authorization method.
      #
      #   class User
      #     # Grants all permissions to self
      #     authorizing do |agent, permission|
      #       agent == self
      #     end
      #   end
      def authorizing(method = nil, &block)
        @authorization_methods = authorization_methods | Array(method || block)
      end
    end

    # Instance methods can be redefined in each Model for custom features
    module InstanceMethods
      # There is authorization if there is any authorization_method that validates 
      # the pair agent, permission
      #
      # Permission can be:
      # ActiveRecord::Authorization::Agent instance
      # Symbol:: describes the action name. Objective will be nil
      #   resource.authorize?(:update, :to => user)
      # Array:: pair of :action, :objective
      #   resource.authorize?([ :create, :attachment ], :to => user)
      #
      # Options:
      # to:: Agent that performs the operation. Defaults to Anyone
      #
      # === Agent Cache
      # Evalutation of authorization_methods are cached by every Agent per request
      #
      def authorize?(permission, options = {})
        agent = options[:to] || Anyone.current

        if agent.authorization_cache[self][permission].nil?
          agent.authorization_cache[self][permission] =
            authorization_methods_eval(agent, permission)
        else
          agent.authorization_cache[self][permission]
        end
      end

      #FIXME: DRY:
      def authorizes?(permission, options = {}) #:nodoc:
        logger.debug "Station: DEPRECATION WARNING \"authorizes?\". Please use \"authorize?\" instead."
        line = caller.select{ |l| l =~ /^#{ RAILS_ROOT }/ }.first
        logger.debug "           in: #{ line }"

        authorize?(permission, options)
      end
      
      private

      def authorization_methods_eval(agent, permission) #:nodoc:
        self.class.authorization_methods.each do |m|
          auth_method_eval = 
            case m
            when Symbol
              send(m, agent, permission)
            when Proc
              m.bind(self).call(agent, permission)
            else
              raise "Invalid Authorization method #{ m }"
            end

          return auth_method_eval unless auth_method_eval.nil?
        end

        false
      end
    end
  end
end
