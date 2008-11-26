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
      self.autoload
    end

    def enable_action_pack
      %w( categories performances ).each do |item|
        require "action_view/helpers/form_#{ item }_helper"
        ::ActionView::Base.send :include, "ActionView::Helpers::Form#{ item.classify.pluralize }Helper".constantize
      end
    end


    def enable_active_record #:nodoc:
      require 'cms/active_record/acts_as'

      ActiveRecord::ActsAs::LIST.each do |item|
        require "cms/active_record/#{ item }"
        ::ActiveRecord::Base.send :include, "CMS::ActiveRecord::#{ item.to_s.classify }".constantize
      end
    end
  end
end

Cms = CMS
