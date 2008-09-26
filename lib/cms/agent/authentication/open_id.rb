module CMS
  module Agent
    # Agent Authentication Methods
    module Authentication
      # OpenID authentication support
      module OpenID
        def self.included(base) #:nodoc:
          base.extend ClassMethods
          base.send :include, InstanceMethods
          base.class_eval do
            attr_accessor :openid_identifier

            has_many :openid_ownings,
                     :as => :agent,
                     :class_name => "CMS::OpenID::Owning"
            has_many :openid_uris,
                     :through => :openid_ownings,
                     :source => :uri
                     
            after_create :add_openid_identifier_to_openid_uris
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
        
        module InstanceMethods #:nodoc: all
          private
          
          def add_openid_identifier_to_openid_uris
            openid_uris << Uri.find_or_create_by_uri(openid_identifier) if openid_identifier
          end
        end
      end
    end
  end
end
