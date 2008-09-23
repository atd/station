require 'cms/core_ext'
require 'cms/mime_types'
require 'cms/autoload'

module CMS
  class << self
    def enable #:nodoc:
      self.enable_mime_types
      enable_active_record
      self.autoload
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
      require 'cms/taggable'
      ActiveRecord::Base.send :include, Taggable
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
