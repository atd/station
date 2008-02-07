require 'digest/sha1'

module CMS
  # Agent(s) can CRUD Content(s) in Container(s), generating Post(s)
  module Agent
    def self.included(base) #:nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      # Provides an ActiveRecord model with Agent capabilities
      #
      # Agent(s) can post Content(s) to Container(s)
      #
      # Options
      # * <tt>authentication</tt>: Array with Authentication methods supported for this Agent. If not defined, Agent will never authenticate
      def acts_as_agent(options = {})
        has_many :openid_ownings,
                 :as => :agent,
                 :class_name => "CMS::OpenID::Owning"

        cattr_reader :authentication_methods
        class_variable_set "@@authentication_methods", options[:authentication]

        if options[:authentication].include? :login_and_password
          # Virtual attribute for the unencrypted password
          attr_accessor :password

          validates_presence_of     :login, :email
          validates_presence_of     :password,                   :if => "needs_password? && password_not_saved?"
          validates_presence_of     :password_confirmation,      :if => "needs_password? && password_not_saved?"
          validates_length_of       :password, :within => 4..40, :if => "needs_password? && password_not_saved?"
          validates_confirmation_of :password,                   :if => "needs_password? && password_not_saved?"
          validates_length_of       :login,    :within => 3..40
          validates_length_of       :email,    :within => 3..100
          validates_uniqueness_of   :login, :email, :case_sensitive => false

          before_save :encrypt_password
          # prevents a user from submitting a crafted form that bypasses activation
          # anything else you want your user to change should be added here.
          attr_accessible :login, :email, :password, :password_confirmation

          # Authenticates a user by their login name and unencrypted password. 
          # Returns the agent or nil.
          def self.authenticate_with_login_and_password(login, password)
            u = include_activation ? 
                  find(:first, :conditions => ['login = ? and activated_at IS NOT NULL', login]) :
                  find_by_login(login)
            u && u.password_authenticated?(password) ? u : nil
          end

          # Encrypts some data with the salt.
          def self.encrypt(password, salt)
            Digest::SHA1.hexdigest("--#{salt}--#{password}--")
          end

          cattr_reader :include_activation
          class_variable_set "@@include_activation", options[:include_activation]

          if options[:include_activation]
            before_create :make_activation_code 
            include ActivationInstanceMethods
          end
        end

        if options[:authentication].include? :openid
          attr_accessor :openid_identifier

          # Find first Agent of this class owning this OpenID URI
          def self.authenticate_with_openid(uri)
            owning = uri.openid_ownings.find :first,
                                             :conditions => [ "agent_type = ?", self.to_s ]
            owning ? owning.agent : nil
          end
        end

        include CMS::Agent::InstanceMethods
      end
    end

    module InstanceMethods
      # Encrypts the password with the user salt
      def encrypt(password)
        self.class.encrypt(password, salt)
      end

      def password_authenticated?(password)
        crypted_password == encrypt(password)
      end

      # Does this Agent needs to set a local password?
      # True if it supports <tt>:login_and_password</tt> authentication method
      # and it hasn't any OpenID Owning
      def needs_password?
        # False is Login/Password is not supported by this Agent
        return false unless authentication_methods.include?(:login_and_password)
        # False if OpenID is suported and there is already an OpenID Owning associated
        ! (authentication_methods.include?(:openid) && !openid_identifier.blank?)
      end

      protected
        # before filter 
        def encrypt_password
          return if password.blank?
          self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
          self.crypted_password = encrypt(password)
        end

        def password_not_saved?
          crypted_password.blank? || !password.blank?
        end
      # Remember methods

      public

      def remember_token? #:nodoc:
        remember_token_expires_at && Time.now.utc < remember_token_expires_at 
      end

      # These create and unset the fields required for remembering users between browser closes
      def remember_me #:nodoc:
        remember_me_for 2.weeks
      end

      def remember_me_for(time) #:nodoc:
        remember_me_until time.from_now.utc
      end

      def remember_me_until(time) #:nodoc:
        self.remember_token_expires_at = time
        self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
        save(false)
      end

      def forget_me
        self.remember_token_expires_at = nil
        self.remember_token            = nil
        save(false)
      end
    end

    module ActivationInstanceMethods
      # Activates the user in the database.
      def activate
        @activated = true
        self.activated_at = Time.now.utc
        self.activation_code = nil
        save(false)
      end

      def active?
        # the existence of an activation code means they have not activated yet
        activation_code.nil?
      end

      # Returns true if the user has just been activated.
      def pending?
        @activated
      end

      protected
        def make_activation_code
          self.activation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
        end
    end
  end
end
