require 'atom/entry'

module ActiveRecord #:nodoc:
  # A Content is a Resource that belongs to a Container.
  # 
  # Include this functionality in your models using ActsAsMethods#acts_as_content
  #
  # == Named Scope
  # You can use the named_scope +in_container+ to get all Contents in some Container.
  #   Content.in_container(some_container) #=> Array of contents in the container
  #
  # Deprecated: Contents instances have entries columns in entry_* when using <tt>entry</tt> option.
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
      # <tt>entry</tt>:: Deprecated: Use Entry to track the relation between Content, Container and Agent. Default to <tt>false</tt>
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
        
        # Warning: this overwrites some methods, like in_container named scope
        if options[:entry]
          include ActiveRecord::Content::Entry
        end
        
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

    module Entry #:nodoc:
      class << self
        def included(base)
          base.class_eval do
            delegate :agent, :container, :parent_id, :to => :entry
            alias :author :agent
            attr_writer :author, :container, :parent_id
            
            has_many :content_entries, 
                     :class_name => "Entry",
                     :dependent => :destroy,
                     :as => :content
            
            before_validation :build_entry
            validates_associated :entry
            after_save :save_entry!
            
            # Named scope in_container returns all Contents in some container
            named_scope :in_container, lambda { |container|
              if container && container.class.acts_as?(:container)
                container_conditions = " AND entries.container_id = '#{ container.id }' AND entries.container_type = '#{ container.class.base_class.to_s }'"
              end
    
              entry_columns = ::Entry.column_names.map{|n| "entries.#{ n } AS entry_#{ n }" }.join(', ')
              { :select => "#{ self.table_name }.*, #{ entry_columns }",
                :joins => "INNER JOIN entries ON entries.content_id = #{ self.table_name }.id AND entries.content_type = '#{ self.base_class.to_s }'" + container_conditions.to_s
              }
            }
            include InstanceMethods
          end
        end
      end
                   
      module InstanceMethods
        # Returns the entry associated with this Content.
        #
        # Normaly using <tt>in_container(@container)</tt> named_scope.
        #
        # Otherwise, return the first entry for this Content: <tt>container_entries.first</tt> or a new one: <tt>container_entries.build</tt>
        #
        # Useful if the request have some Container:in the path
        #   GET /container/1/content/ #=> @content.entry
        #
        def entry
          @entry ||= if entry_attributes.any? 
                       e = ::Entry.new(entry_attributes)
                       if e.valid?
                         e.id = entry_attributes[:id]
                         e.instance_variable_set("@new_record", false)
                         e
                       else
                         nil
                       end
                    else 
                      content_entries.first || content_entries.build 
                    end
        end
        
        # Has this Content been posted in this Container? Is there any Entry linking both?
        def posted_in?(container)
          return false unless container
          content_entries.select{ |p| p.container == container }.any?
        end
        
        private
        
        def build_entry #:nodoc:
          entry.agent = @author if @author
          entry.container = @container if @container
          entry.parent_id = @parent_id if @parent_id
        end
        
        def save_entry! #:nodoc:
          entry.content = self
          raise "Invalid entry when saving #{ self.inspect }" unless entry.valid?
          entry.save!
        end
  
        def entry_attributes #:nodoc:
          returning HashWithIndifferentAccess.new do |entry_attrs|
            attributes.each do |content_attr|
              entry_attrs[$1] = content_attr.last if content_attr.first =~ /^entry_(.*)$/
            end
          end
        end
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


