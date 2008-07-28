require 'cms/core_ext'
require 'cms/mime_types'
require 'cms/autoload'
require 'cms/param_parsers'

module CMS
  class << self
    def enable #:nodoc:
      self.enable_mime_types
      enable_routes
      enable_active_record
      self.autoload
      self.enable_param_parsers
    end

    def enable_routes
      ActionController::Routing::RouteSet::Mapper.class_eval do
        def cms
          resource :"cms/site"

          open_id_complete 'cms/session', 
            { :controller => 'cms/sessions', 
              :action     => 'create',
              :conditions => { :method => :get },
              :open_id_complete => true }

          resource :"cms/session"

          login 'login',   :controller => 'cms/sessions', :action => 'new'
          logout 'logout', :controller => 'cms/sessions', :action => 'destroy'

          if CMS::Agent.activation_class
            activate 'activate/:activation_code', 
                     :controller => CMS::Agent.activation_class.to_s.tableize, 
                     :method => 'activate', 
                     :activation_code => nil
            forgot_password 'forgot_password', 
                     :controller => CMS::Agent.activation_class.to_s.tableize,
                     :method => 'forgot_password'
            reset_password 'reset_password', 
                           :controller => CMS::Agent.activation_class.to_s.tableize,
                           :method => 'reset_password'
          end

          resources :"cms/posts", :member => { :media => :any,
                                                   :edit_media => :get,
                                                   :details => :any }
          resources :"cms/categories"

          resources *((CMS.contents | CMS.agents) - CMS.containers)

          resources(*(CMS.containers - Array(:"cms/sites"))) do |container|
            container.resources(*CMS.contents)
            container.resources :"cms/posts", :"cms/categories"
          end
        end
      end
    end

    def enable_active_record #:nodoc:
      #FIXME: DRY
      require 'cms/agent'
      ActiveRecord::Base.send :include, Agent
      require 'cms/content'
      ActiveRecord::Base.send :include, Content
      require 'cms/container'
      ActiveRecord::Base.send :include, Container
      require 'cms/sortable'
      ActiveRecord::Base.send :include, Sortable
    end

    # Return an Array with the class constants that act as a Container
    def container_classes
      @@containers.map(&:to_class)
    end

    # Return an Array with the class constants that act as an Agent
    def agent_classes
      @@agents.map(&:to_class)
    end

    # Return an Array with the class constants that act as a Content
    def content_classes
      @@contents.map(&:to_class)
    end

    # Return an Array with all the Mime::Types supported by AtomPub
    def atompub_mime_types
      types = []
      for klass in content_classes do
        types |= Mime::Type.parse klass.content_options[:atompub_mime_types]
      end
      # Only return registered symbols
      types.select{ |t| t.instance_variable_get("@symbol") }
    end

    def mime_types
      # TODO: DRY cms/mime_types
      atompub_mime_types | [ Mime::ATOM, Mime::ATOMSVC, Mime::ATOMCAT, Mime::XRDS ]
    end
  end
end

Cms = CMS
