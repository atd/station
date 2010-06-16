module ActiveRecord #:nodoc:
  module Agent
    module OpenidServer
      class << self
        def included(base)
          base.send :include, InstanceMethods

          base.class_eval do 
            has_many :openid_ownings,
                     :as => :agent,
                     :class_name => "OpenIdOwning",
                     :dependent => :destroy
            has_many :openid_uris,
                     :through => :openid_ownings,
                     :source => :uri

            has_many :openid_trusts,
                     :as => :agent,
                     :class_name => "OpenIdTrust",
                     :dependent => :destroy
            has_many :openid_trust_uris, 
                     :through => :openid_trusts,
                     :source => :uri

            after_save :update_openid_server_ownings
          end
        end

        def classes
          ActiveRecord::Agent.classes.select{ |k| k.agent_options[:openid_server] }
        end
      end

      module InstanceMethods
        # Set OpenID Ownings for the URIs hosted in this server
        def update_openid_server_ownings
          uris_path = "#{ Site.current.domain }/#{ self.class.to_s.tableize }/#{ to_param }"
          uris = [ Uri.find_or_create_by_uri("http://#{ uris_path }") ]
          uris << Uri.find_or_create_by_uri("https://#{ uris_path }") if Site.current.ssl?

          # Destroy old OpenID local URIs
          openid_ownings.local.each do |ow|
            ow.destroy unless uris.include?(ow.uri)
          end

          # Add new OpenID URIs
          uris.each do |u|
            unless openid_ownings.local.map(&:uri).include?(u)
              openid_ownings.local.create :uri => u
            end
          end
        end
      end
    end
  end
end
