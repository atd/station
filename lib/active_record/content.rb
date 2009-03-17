require 'atom/entry'

module ActiveRecord #:nodoc:
  # A Content is a Resource that belongs to a Container.
  # 
  # Include this functionality in your models using ActsAsMethods#acts_as_content
  #
  # == Named Scope
  # You can use the named_scope +in_container+ to get all Contents in some Container.
  #   Content.in_container(some_container) #=> Array of contents in the container
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
      # container:: The Container for the Contents
      # page:: Number of page.
      # per_page:: Number of Contents per page
      def all(options = {})
        Inquirer.all(options)
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
          conditions = HashWithIndifferentAccess.new

          if container && container.class.acts_as?(:container)
            conditions["#{ table_name }.#{ container_reflection.primary_key_name }"] =
              container.id
            if container_reflection.options[:polymorphic]
              conditions["#{ table_name }.#{ container_reflection.options[:foreign_type] }"] =
              container.class.base_class.to_s
            end
          end

          { :conditions => conditions }
        }

        acts_as_stage
        acts_as_sortable
        acts_as_categorizable

        extend  ClassMethods
        include InstanceMethods
      end
    end

    module ClassMethods
      # The ActiveRecord reflection that represents the Container for this model
      def container_reflection
        reflections[content_options[:reflection]]
      end
    end

    module InstanceMethods
      # Has this Content been posted in this Container? Is there any Entry linking both?
      # Obsolete?  
      def posted_in?(container)
        container == self.container
      end
    end

    class Inquirer < ActiveRecord::Base #:nodoc:
      @colums = Array.new
      @columns_hash = { "type" => :fake }

      class << self
        def query(options = {})
          options[:select]   ||= "id, title, created_at, updated_at"
          container = options.delete(:container)

          content_classes = container ?
                             container.class.contents.map(&:to_class) :
                             ActiveRecord::Content.classes

          content_classes.map { |content|
            params = Hash.new.replace options
            params[:select] += ", ( SELECT \"#{ content }\" ) AS type"
            params[:select] += if content.resource_options[:has_media]
                                 ", content_type"
                               else
                                 ", ( SELECT NULL ) AS content_type"
                               end
            content.parents.in_container(container).construct_finder_sql(params)
          }.join(" UNION ")
        end

        def all(options = {})
          order     = options.delete(:order)    || "updated_at DESC"
          per_page  = options.delete(:per_page) || 30
          page      = options.delete(:page)     || 1
          offset = ( page.to_i - 1 ) * per_page

          WillPaginate::Collection.create(page, per_page) do |pager|
            contents = find_by_sql "SELECT * FROM (#{ query(options.dup) }) AS contents ORDER BY contents.#{ order } LIMIT #{ per_page } OFFSET #{ offset }"
            pager.replace(contents)

            pager.total_entries = count(options)
          end
        end

        def count(options = {})
          count_by_sql "SELECT COUNT(*) FROM (#{ query(options) })"
        end
      end
    end
  end
end


