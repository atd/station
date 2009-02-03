module ActiveRecord #:nodoc:
  module Agent
    # Agents Activation support
    #
    # Activation verifies the Agent has an accesible email
    #
    # TODO: Currently, only affects LoginAndPassword authentication
    module Activation
      def self.included(base) #:nodoc:
        base.class_eval do
          before_create "make_activation_code"
        end
      end

      # Activates the agent in the database.
      def activate
        @activated = true
        self.activated_at = Time.now.utc
        self.activation_code = nil
        save(false)
      end

      # Is the Agent activated?
      def active?
        # the existence of an activation code means they have not activated yet
        activation_code.nil?
      end

      # Returns true if the agent has just been activated.
      def pending?
        @activated
      end

      # Activate agent recovery password mechanism. 
      # Generates password reset code
      def forgot_password
        @forgotten_password = true
        self.make_reset_password_code
        save(false)
      end

      # User did reset the password
      def reset_password
        @reset_password = true
        self.reset_password_code = nil
        save(false)
      end

      # Did the agent recently reset the passowrd?
      def recently_reset_password?
        @reset_password
      end

      # Did the agent recently asked for password reset?
      def recently_forgot_password?
        @forgotten_password
      end


      protected
        def make_activation_code #:nodoc:
          self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
        end

        def make_reset_password_code #:nodoc:
          self.reset_password_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
        end
    end
  end
end
