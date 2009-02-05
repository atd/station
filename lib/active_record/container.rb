module ActiveRecord #:nodoc:
  # Container(s) are models receiving Content(s) posted by Agent(s)
  module Container
    include ActsAs

    class << self
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
        # * <tt>contents</tt>: an Array of Contents that can be posted to this Container. Ex: [ :article, :image ]. Defaults to all available Content models.
      # * <tt>name</tt>: alias attribute for Content presentation
      #
      def acts_as_container(options = {})
        ActiveRecord::Container.register_class(self)

        options[:contents] ||= ActiveRecord::Content.symbols
        send(:alias_attribute, :name, options.delete(:name)) if options[:name]

        cattr_reader :container_options
        class_variable_set "@@container_options", options

        has_many :container_entries, 
                 :class_name => "Entry",
                 :dependent => :destroy,
                 :as => :container


        acts_as_categories_domain

        # All Containers are Stages by default:
        send(:acts_as_stage) unless respond_to?(:stage_options)

        include ActiveRecord::Container::InstanceMethods
      end
    end


    # Instance methods can be redefined in each Model for custom features
    module InstanceMethods
    end
  end
end
