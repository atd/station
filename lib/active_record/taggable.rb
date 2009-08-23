# Some of this code comes from has_many_polymorphs plugin
# Copyright 2007 Cloudburst, LLC. Licensed under the AFL 3.
#
module ActiveRecord #:nodoc:
  # Taggable ActiveRecord module
  module Taggable
    def self.included(base) #:nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      # Provides an ActiveRecord model with Taggable capabilities
      #
      # Example:
      #   acts_as_taggable
      def acts_as_taggable
        ActiveRecord::Taggable.register_class(self)

        has_many :taggings, :as => :taggable,
                            :dependent => :destroy
        has_many :tags, :through => :taggings do
          def to_s
            self.map(&:name).sort.join(Tag::DELIMITER)
          end
        end

        include InstanceMethods

        send :attr_accessor, :_tags
        after_save :_save_tags!
      end
    end

    module InstanceMethods
      # Add tags to <tt>self</tt>. Accepts a string of tagnames, an array of tagnames, an array of ids, or an array of Tags.
      #
      # We need to avoid name conflicts with the built-in ActiveRecord association methods, thus the underscores.
      def _add_tags incoming
        tag_cast_to_string(incoming).each do |tag_name|
          begin
            tag = Tag.find_or_create_by_name(tag_name)
            raise "tag could not be saved: #{tag_name}" if tag.new_record?
            self.tags  << tag
          rescue ActiveRecord::StatementInvalid => e
            raise unless e.to_s =~ /duplicate/i
          end
        end
      end
    
      # Removes tags from <tt>self</tt>. Accepts a string of tagnames, an array of tagnames, an array of ids, or an array of Tags.  
      def _remove_tags outgoing
        outgoing = tag_cast_to_string(outgoing)
       
        tags.delete(*(tags.select do |tag|
          outgoing.include? tag.name    
        end))
      end

      # Returns the tags on <tt>self</tt> as a string.
      def tag_list
        tags.reload
        tags.to_s
      end
   
      # Replace the existing tags on <tt>self</tt>. Accepts a string of tagnames, an array of tagnames, an array of ids, or an array of Tags.
      def tag_with list    
        list = tag_cast_to_string(list)
               
        # Transactions may not be ideal for you here; be aware.
        Tag.transaction do 
          current = tags.map(&:name)
          _add_tags(list - current)
          _remove_tags(current - list)
        end
        
        self
      end

      
      private 

      def _save_tags!
        return unless @_tags
        tag_with @_tags
        @_tags = nil
      end
      
      def tag_cast_to_string obj #:nodoc:
        case obj
          when Array
            obj.map! do |item|
              case item
                when Fixnum then Tag.find(item).name # This will be slow if you use ids a lot.
                when Tag then item.name
                when String then item
                else
                  raise "Invalid type"
              end
            end              
          when String
            obj = obj.split(Tag::DELIMITER).map do |tag_name| 
              tag_name.strip.squeeze(" ")
            end
          else
            raise "Invalid object of class #{obj.class} as tagging method parameter"
        end.flatten.compact.map(&:downcase).uniq
      end 
    end
  end
end
