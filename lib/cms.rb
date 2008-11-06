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
      require 'cms/active_record/acts_as'

      ActiveRecord::ActsAs::LIST.each do |item|
        require "cms/active_record/#{ item }"
        ::ActiveRecord::Base.send :include, "ActiveRecord::#{ item }".constantize
      end
    end
  end
end

Cms = CMS
