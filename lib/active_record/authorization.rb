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
      def acl_sets
        @acl_sets ||= []
      end

      protected

      def acl_set(method = nil, &block)
        #FIXME
        @acl_sets = ( acl_sets << (method || block)).flatten.uniq
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
        acl.authorize?(permission, options)
      end

      #FIXME: DRY:
      def authorizes?(permission, options = {})
        logger.debug "Station: DEPRECATION WARNING \"authorizes?\". Please use \"authorize?\" instead."
        line = caller.select{ |l| l =~ /^#{ RAILS_ROOT }/ }.first
        logger.debug "           in: #{ line }"

        authorize?(permission, options)
      end

      def acl
        returning(ACL.new(self)) do |acl|
          self.class.acl_sets.each do |set|
            case set
            when Symbol, String
              send(set, acl)
            when Proc
              set.call(acl, self)
            else
              raise "Invalid ACL Set: #{ set.inspect }"
            end
          end
        end
      end
    end
  end
end
