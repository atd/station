module ActiveRecord #:nodoc:
  # A Content is a Resource that belongs to a Container.
  # 
  # Include this functionality in your models using ActsAsMethods#acts_as_content
  #
  # == Named Scope
  # You can use the named_scope +in_container+ to get all Contents in some Container.
  #   Content.in_container(some_container) #=> Array of contents in the container
  #
  # == Authorization
  # The Content will incorporate an authorization_block.
  # 
  # This authorization block ask single permissions to its Container.
  #
  #   class Task
  #     belongs_to :project
  #     acts_as_content :reflection => :project
  #   end
  #
  #   task.authorize?(:update) #=> will ask task.project.authorize?([ :update, :content ]) ||
  #                            #            task.project.authorize?([ :update, :task ])
  #   
  #
  module Content
    class << self
      def included(base) # :nodoc:
        # Fake named_scope to ActiveRecord instances that aren't Contents
        base.named_scope :in_container, lambda { |container| {} }
        base.extend ActsAsMethods
      end

      # List of Contents from many models
      #
      # Options::
      # containers:: The Container for the Contents
      # page:: Number of page.
      # per_page:: Number of Contents per page
      def all(options = {})
        ActiveRecord::Content::Inquirer.all(options)
      end
    end

    module ActsAsMethods
      # Provides an ActiveRecord model with Content capabilities
      #
      # == Options
      # <tt>reflection</tt>:: Name of the (usually <tt>belongs_to</tt>) association that relates this model with its Container. Defaults to <tt>:container</tt>
      def acts_as_content(options = {})
        ActiveRecord::Content.register_class(self)

        options[:reflection] ||= :container

        cattr_reader :content_options
        class_variable_set "@@content_options", options

        if options[:reflection] != :container
          alias_attribute :container, options[:reflection]
          attr_protected options[:reflection]
          attr_protected reflections[options[:reflection]].primary_key_name
          if reflections[options[:reflection]].options[:polymorphic]
            attr_protected reflections[options[:reflection]].options[:foreign_type]
          end
        end
        attr_protected :container, :container_id, :container_type

        named_scope :in_container, lambda { |container|
          { :conditions => container_conditions(container) }
        }

        acts_as_sortable

        authorizing do |agent, permission|
          return nil unless container.present?

          return nil unless permission.is_a?(String) || permission.is_a?(Symbol)

          container.authorize?([permission, :content], :to => agent) ||
            container.authorize?([permission, self.class.to_s.underscore.to_sym], :to => agent) ||
            nil
        end

        extend  ClassMethods
        include InstanceMethods
      end
    end

    module ClassMethods
      # The ActiveRecord reflection that represents the Container for this model
      def container_reflection
        reflections[content_options[:reflection]]
      end

      def container_conditions(container)
        case container
        when NilClass
          ""
        when Array
          container.map{ |c| container_conditions(c) }.join(" OR ")
        else
          if container.class.acts_as?(:container)
            c = "#{ table_name }.#{ container_reflection.primary_key_name } = '#{ container.id }'"
            if container_reflection.options[:polymorphic]
              c << " AND #{ table_name }.#{ container_reflection.options[:foreign_type] } = '#{ container.class.base_class }'"
            end
            "(#{ c })"
          else
            ""
          end
        end
      end

      # ActiveRecord Scope used by ActiveRecord::Content::Inquirer
      #
      # By default uses roots.in_container find scope
      #
      # Options:
      # container:: The container passed to in_container named_scope
      def content_inquirer_scope(options = {})
        inquirer_scope = roots.in_container(options[:container]).scope(:find)
      end

      # Construct SQL query used by ActiveRecord::Content::Inquirer
      #
      # params is a hash of parameters passed to ActiveRecord, like in a regular query
      #
      # scope_options will be passed to content_inquirer_scope
      #
      def content_inquirer_query(params = {}, scope_options = {})
        inquirer_scope = content_inquirer_scope(scope_options)

        # Clean scope parameters like :order
        inquirer_scope.delete(:order)

        with_scope(:find => inquirer_scope) do
          construct_finder_sql(params)
        end
      end
    end

    module InstanceMethods
      # Has this Content been posted in this Container? Is there any Entry linking both?
      # Obsolete?  
      def posted_in?(container)
        container == self.container
      end
    end
  end
end


