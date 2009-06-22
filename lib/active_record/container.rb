module ActiveRecord #:nodoc:
  # A Container is a model that have many Contents
  #
  # Include this functionality in your modules using ActsAsMethods#acts_as_container
  module Container
    class << self
      def included(base) #:nodoc:
        base.extend ActsAsMethods
      end
    end

    module ActsAsMethods
      # Provides an ActiveRecord model with Container capabilities
      #
      # Options:
      # <tt>contents</tt>:: an Array of Contents that can be posted to this Container. Ex: [ :article, :image ]. Defaults to all available Content models.
      def acts_as_container(options = {})
        ActiveRecord::Container.register_class(self)

        cattr_reader :container_options
        class_variable_set "@@container_options", options

        has_many :sources, :as => :container,
                           :dependent => :destroy

        acts_as_categories_domain

        extend  ClassMethods
        include InstanceMethods
      end
    end

    module ClassMethods
      # Array of symbols representing the Contents that this Container supports
      def contents
        container_options[:contents] || ActiveRecord::Content.symbols
      end
    end


    # Instance methods can be redefined in each Model for custom features
    module InstanceMethods #:nodoc:
    end
  end
end
