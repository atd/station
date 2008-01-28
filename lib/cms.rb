require 'cms/core_ext'
require 'cms/autoload'
require 'cms/utils'

module CMS
  class << self
    def enable
      enable_classes
      enable_active_record
      self.autoload
    end

    def enable_classes
      return if defined?(CMS::Post)
      require 'cms/post'
    end

    def enable_active_record
      #FIXME: DRY
      require 'cms/agent'
      ActiveRecord::Base.send :include, Agent
      require 'cms/content'
      ActiveRecord::Base.send :include, Content
      require 'cms/container'
      ActiveRecord::Base.send :include, Container
      end
  end
end
