module CMS
  module ActiveRecord
    # Provides some functionality to modules that enhance ActiveRecord 
    # with acts_as_something
    module ActsAs #:nodoc:
      LIST = [ :container, :agent, :content, :stage, :taggable, :logotypable, :sortable ]

      class << self
        def included(base) #:nodoc:
          base.instance_variable_set "@symbols", Array.new
          base.extend ClassMethods
        end
      end

      module ClassMethods
        def symbols
          @symbols
        end

        def register_class(klass)
          @symbols |= Array(klass.to_s.tableize.to_sym)
        end

        def classes
          @symbols.map(&:to_class)
        end
      end
    end
  end
end
