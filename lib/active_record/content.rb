require 'atom/entry'

module ActiveRecord #:nodoc:
  # A Content is a Resource that belongs to a Container.
  #
  # == Named Scope
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
      def acts_as_content(options = {})
        ActiveRecord::Content.register_class(self)

        cattr_reader :content_options
        class_variable_set "@@content_options", options

        attr_writer :entry
        validates_associated :entry
        after_save :entry_save!


        has_many :content_entries, 
                 :class_name => "Entry",
                 :dependent => :destroy,
                 :as => :content

        acts_as_stage
        acts_as_sortable
        acts_as_categorizable

        # Named scope in_container returns all Contents in some container
        named_scope :in_container, lambda { |container|
          if container && container.respond_to?("container_options")
            container_conditions = " AND entries.container_id = '#{ container.id }' AND entries.container_type = '#{ container.class.base_class.to_s }'"
          end

          entry_columns = Entry.column_names.map{|n| "entries.#{ n } AS entry_#{ n }" }.join(', ')
          { :select => "#{ self.table_name }.*, #{ entry_columns }",
            :joins => "INNER JOIN entries ON entries.content_id = #{ self.table_name }.id AND entries.content_type = '#{ self.base_class.to_s }'" + container_conditions.to_s
          }
        }

        include ActiveRecord::Content::InstanceMethods
      end
    end

    module InstanceMethods
      # Returns the entry associated with this Content.
      #
      # Normaly using <tt>in_container(@container)</tt> named_scope.
      #
      # Otherwise, return the first entry for this Content: <tt>container_entries.first</tt>
      #
      # Useful if the request have some Container:in the path
      #   GET /container/1/content/ #=> @content.entry
      #
      def entry
        @entry ||= if entry_attributes.any? 
                     e = Entry.new(entry_attributes)
                     if e.valid?
                       e.id = entry_attributes[:id]
                       e.instance_variable_set("@new_record", false)
                       e
                     else
                       nil
                     end
                  else 
                    self.content_entries.first
                  end
      end

      # Has this Content been posted in this Container? Is there any Entry linking both?
      def posted_in?(container)
        return false unless container
        content_entries.select{ |p| p.container == container }.any?
      end
      
      # The author of this Content
      def author
        entry ?
          entry.agent :
          nil
      end

      # The container of this Content
      def container
        entry ?
          entry.container :
          nil
      end

      private

      def entry_save! # :nodoc:
        if entry
          entry.content = self
          raise "Invalid entry when saving #{ self.inspect }" unless entry.valid?
          entry.save!
        else
          logger.warn "CMSplugin Warning: Saving Content without an Entry"
          # Update entries updated_at
          self.content_entries.map(&:save!)
        end
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
end
