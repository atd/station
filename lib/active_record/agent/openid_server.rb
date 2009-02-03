module ActiveRecord #:nodoc:
  module Agent
    module OpenidServer
      class << self
        def included(base)
          base.send :include, InstanceMethods

          base.class_eval do 
            has_many :openid_ownings,
                     :as => :agent,
                     :class_name => "CMS::OpenID::Owning",
                     :dependent => :destroy
            has_many :openid_uris,
                     :through => :openid_ownings,
                     :source => :uri

            has_many :openid_trusts,
                     :as => :agent,
                     :class_name => "CMS::OpenID::Trust",
                     :dependent => :destroy
            has_many :openid_trust_uris, 
                     :through => :openid_trusts,
                     :source => :uri

            after_create :create_openid_server_ownings
          end
        end
      end

      module InstanceMethods
        # Create OpenID Ownings for the URIs hosted in this server
        def create_openid_server_ownings
          uris_path = "#{ Site.current.domain }/#{ self.class.to_s.tableize }/#{ to_param }"
          uris = [ Uri.find_or_create_by_uri("http://#{ uris_path }", :local => true) ]
          uris << Uri.find_or_create_by_uri("https://#{ uris_path }", :local => true) if Site.current.ssl?

          uris.each do |u|
            openid_uris << u unless openid_uris.include?(u)
          end
        end
      end
    end
  end
end
