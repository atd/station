module ActiveRecord #:nodoc:
  # Authorization module provides ActiveRecord models with an authorization framework.
  #
  # Every ActiveRecord::Base descendant can authorize actions to Agents.
  #
  # == Authorization Chain
  # Each ActiveRecord model have an Authorization Chain (AC) associated. The AC is a sequence of 
  # Authorization Blocks (AB). Each AB should enclose only one security policy.
  #
  # When asking some model if some Agent is allowed to perform an action, the Authorization Chain is
  # evaluated. Each AB is executed in order. When one AB gives a result (true or false), the AC is
  # halted and action is allowed or denied.
  #
  # If the AB result is nil, the next AB is evaluated. When no AB remain, auhorization is denied.
  #
  # Authorization Blocks are defined using ActiveRecord::Authorization::ClassMethods#authorizing method.
  #
  # Consider the following example of Authorization Chain
  #
  #   class Example
  #     authorizing do |user, permission|
  #       if user.is_superadmin?
  #         true
  #       end
  #     end
  #
  #     authorizing do |user, permission|
  #       if user == self.author
  #         true
  #       end
  #     end
  #
  #     authorizing do |user, permission|
  #       if user.is_banned?
  #         false
  #       end
  #     end
  #   end
  #
  # The class Example has 3 Authorization Blocks, that will be evaluated in order until a response is obtained.
  #
  # Authorization is queried using ActiveRecord::Authorization::InstanceMethods#authorize? method. For the example above:
  #   example.authorize?(:read, :to => superadmin) #=> true
  #   example.authorize?(:update, :to => example.author) #=> true
  #   example.authorize?(:destroy, :to => banned_user) #=> false
  #
  # === Station default Authorization Blocks
  # Station provides 2 default Authorization Blocks for Contents and Stages. See ActiveRecord::Content and ActiveRecord::Stage
  #
  # == Authorization Cache
  # Permissions are cached for each ActiveRecord instance during the request. This improves performance
  # significantly.
  #
  # The cache consist on a Hash of Hashes, like:
  #   post.authorization_cache #=> { User.first => { :read => true, :update => false },
  #                           Anonymous.current => { :read => false } }
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

      # Define a new Authorization Block.
      #
      # A sequence of Authorization Blocks compose the Authorization Chain. Each model AC is evaluated
      # when requesting authorization permissions to each instance. See ActiveRecord::Authorization
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

      def authorization_delegate(relation, options = {})
        options[:as] ||= name.underscore

        class_eval <<-AUTH
        authorizing do |agent, permission|
          return nil unless #{ relation }.present?

          return nil unless permission.is_a?(String) || permission.is_a?(Symbol)

          #{ relation }.authorize?([permission, :#{ options[:as] }], :to => agent) || nil
        end
        AUTH
      end
    end

    # Instance methods can be redefined in each Model for custom features
    module InstanceMethods
      # Does this instance allows or denies permission?
      #
      # Is the response is cached, it is responded immediately. Else, the Authorization Chain 
      # is evaluated. See ActiveRecord::Authorization for information on how it works
      #
      # Permission can be:
      # Symbol:: describes the action name. Objective will be nil
      #   resource.authorize?(:update, :to => user)
      # Array:: pair of :action, :objective
      #   resource.authorize?([ :create, :attachment ], :to => user)
      #
      # Options:
      # to:: Agent that performs the operation. Defaults to Anyone
      #
      def authorize?(permission, options = {})
        agent = options[:to] || Anyone.current

        if authorization_cache[agent][permission].nil?
          authorization_eval = authorization_methods_eval(agent, permission)
          # Deny by default
          authorization_eval = false if authorization_eval.nil?
          # Cache the evalutation for better performance
          authorization_cache[agent][permission] = authorization_eval
        else
          authorization_cache[agent][permission]
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

      # Authorization Cache
      def authorization_cache #:nodoc:
        @authorization_cache ||= Hash.new{ |agent, permission| agent[permission] = Hash.new }
      end

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

        nil
      end
    end
  end
end
