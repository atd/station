module CMS
  module Agent
    # Agent Authentication Methods
    module Authentication
      # OpenID authentication support
      module OpenID
        def self.included(base) #:nodoc:
          base.extend ClassMethods
          base.class_eval do
            attr_accessor :openid_identifier

            has_many :openid_ownings,
                     :as => :agent,
                     :class_name => "CMS::OpenID::Owning"
          end
        end

        module ClassMethods
          # Find first Agent of this class owning this OpenID URI
          def authenticate_with_openid(uri)
            owning = uri.openid_ownings.find :first,
                                             :conditions => [ "agent_type = ?", self.to_s ]
            owning ? owning.agent : nil
          end
        end
      end
    end
  end
end
