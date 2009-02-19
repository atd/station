require 'atom/entry'

module ActiveRecord #:nodoc:
  # A Content is a Resource that belongs to a Container.
  # 
  # == Entries
  # The relation between Content, Container and Agent can be tracked by an Entry
  # See options in acts_as_content
  #
  # === Named Scope
  # You can use the named_scope +in_container+ to get all Contents in some Container.
  #   Content.in_container(some_container) #=> Array of contents in the container
  #
  # Contents instances have entries columns in entry_*
  module Content
    include ActsAs

    class << self
      def included(base) # :nodoc:
        base.extend ClassMethods
      end
    end

    module ClassMethods
      # Provides an ActiveRecord model with Content capabilities
      #
      # == Options
      # <tt>reflection</tt>:: Name of the (usually <tt>belongs_to</tt>)association that relates this model with its Container. Defaults to <tt>:container</tt>
      # <tt>entry</tt>:: Use Entry to track the relation between Content, Container and Agent. Default to <tt>false</tt>
      def acts_as_content(options = {})
        ActiveRecord::Content.register_class(self)

        options[:reflection] ||= :container

        cattr_reader :content_options
        class_variable_set "@@content_options", options

        if options[:reflection] != :container
          alias_attribute :container, options[:reflection]
        end

        named_scope :in_container, lambda { |container|
          conditions = HashWithIndifferentAccess.new

          if container && container.respond_to?("container_options")
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

        include ActiveRecord::Content::InstanceMethods
        
        # Warning: this overwrites some methods, like in_container named scope
        if options[:entry]
          include ActiveRecord::Content::Entry
        end
        
      end

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
              if container && container.respond_to?("container_options")
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
        
        # Has this Content been posted in this Container? Is there any Entry linking both?
        def posted_in?(container)
          return false unless container
          content_entries.select{ |p| p.container == container }.any?
        end
      end
    end
  end
end
