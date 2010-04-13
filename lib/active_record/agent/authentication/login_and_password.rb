module ActiveRecord #:nodoc:
  module Agent
    # Agent Authentication Methods
    module Authentication
      # Login and Password authentication support
      module LoginAndPassword
        def self.included(base) #:nodoc:
          base.extend ClassMethods
          base.class_eval do
            agent_options[:login_and_password]         ||= Hash.new
            unless agent_options[:login_and_password].key?(:login)
              agent_options[:login_and_password][:login] = :login
            end
            unless agent_options[:login_and_password].key?(:email)
              agent_options[:login_and_password][:email] = :email
            end

            # Virtual attribute for the unencrypted password
            attr_accessor :password

            validates_presence_of     :password,                   :if => "needs_password? && password_not_saved?"
            validates_presence_of     :password_confirmation,      :if => "needs_password? && password_not_saved?"
            validates_length_of       :password, :within => 4..40, :if => "needs_password? && password_not_saved?"
            validates_confirmation_of :password,                   :if => "needs_password? && password_not_saved?"
            # prevents a user from submitting a crafted form that bypasses activation
            # anything else you want your user to change should be added here.
            attr_accessible :password, :password_confirmation

            if agent_options[:login_and_password][:login]
              validates_presence_of     :login
              validates_length_of       :login, :within => 1..40
              validates_uniqueness_of   :login, :case_sensitive => false
              attr_accessible           :login
            end

            # TODO: this should be in other module related with Agent contact
            if agent_options[:login_and_password][:email]
              validates_presence_of     :email
              validates_length_of       :email, :within => 5..100
              validates_uniqueness_of   :email, :case_sensitive => false
              attr_accessible           :email
            end

            before_save :encrypt_password

            include InstanceMethods
          end
        end

        module ClassMethods
          # Authenticates a user by their login name and unencrypted password. 
          # Returns the agent or nil.
          def authenticate_with_login_and_password(login, password)
            u = find_by_login(login)
            u && u.password_authenticated?(password) ? u : nil
          end

          # Encrypts some data with the salt.
          def encrypt(password, salt)
            Digest::SHA1.hexdigest("--#{salt}--#{password}--")
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

          protected
            # before filter 
            def encrypt_password
              return if password.blank?
              self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
              self.crypted_password = encrypt(password)
            end

            def password_not_saved?
              crypted_password.blank? || password.present?
            end

        end
      end
    end
  end
end
