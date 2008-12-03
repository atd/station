require 'cms/core_ext'
require 'cms/mime_types'
require 'cms/autoload'
require 'cms/inflections'

module CMS
  class << self
    def enable #:nodoc:
      enable_mime_types
      enable_action_pack
      enable_active_record
      enable_singular_agents
      self.autoload
    end

    def enable_action_pack #:nodoc:
      %w( categories performances logotype ).each do |item|
        require "action_view/helpers/form_#{ item }_helper"
        ::ActionView::Base.send :include, "ActionView::Helpers::Form#{ item.camelcase }Helper".constantize
      end
    end


    def enable_active_record #:nodoc:
      require 'cms/active_record/acts_as'

      ActiveRecord::ActsAs::LIST.each do |item|
        require "cms/active_record/#{ item }"
        ::ActiveRecord::Base.send :include, "CMS::ActiveRecord::#{ item.to_s.classify }".constantize
      end
    end

    # Load SingularAgents
    def enable_singular_agents #:nodoc:
      if SingularAgent.table_exists?
        SingularAgent
        Anonymous.current
        Anyone.current
      end
    end
  end
end

Cms = CMS
