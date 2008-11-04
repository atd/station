module CMS 
  # Container(s) are models receiving Content(s) posted by Agent(s)
  module Container
    class << self
      # Container classes
      def classes
        CMS.logotypables.map(&:to_class)
      end

      def included(base) #:nodoc:
        base.extend ClassMethods
      end
    end

    module ClassMethods
      # Provides an ActiveRecord model with Container capabilities
      #
      # Content(s) are posted by Agent(s) to Container(s), giving Entry(s)
      #
      # Options:
      # * <tt>content_types</tt>: an Array of Content that can be posted to this Container. Ex: [ :articles, :images ]. Defaults to all available Content(s)
      # * <tt>name</tt>: alias attribute for Content presentation
      #
      def acts_as_container(options = {})
        CMS.register_model(self, :container)
        def self.inherited(subclass)
          super
          CMS.register_model(subclass, :container)
        end

        send(:alias_attribute, :name, options.delete(:name)) if options[:name]

        cattr_reader :container_options
        class_variable_set "@@container_options", options

        has_many :container_entries, 
                 :class_name => "Entry",
                 :dependent => :destroy,
                 :as => :container


        has_many :container_categories,
                 :class_name => "Category",
                 :dependent => :destroy,
                 :as => :container

        # All Containers are Stages by default:
        send(:acts_as_stage) unless respond_to?(:stage_options)

        include CMS::Container::InstanceMethods
      end
    end


    # Instance methods can be redefined in each Model for custom features
    module InstanceMethods
      def accepted_content_types
        self.class.container_options[:content_types] || CMS.contents
      end
    end
  end
end
