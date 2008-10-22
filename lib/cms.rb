require 'cms/core_ext'
require 'cms/mime_types'
require 'cms/autoload'
require 'cms/inflections'

module CMS
  class << self
    def enable #:nodoc:
      enable_mime_types
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
      require 'cms/stage'
      ActiveRecord::Base.send :include, Stage
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
  end
end

Cms = CMS
