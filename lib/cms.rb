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
      require 'action_view/helpers/form_categories_helper'
      ::ActionView::Base.send :include, ActionView::Helpers::FormCategoriesHelper
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
