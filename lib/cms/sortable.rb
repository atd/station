module CMS 
  # Container(s) are models receiving Content(s) posted by Agent(s)
  module Sortable
    def self.included(base) #:nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      # Provides an ActiveRecord model with Sort capabilities
      def acts_as_sortable(options = {})
        options[:columns] ||= self.columns.map{ |c| c.name.to_sym }

        cattr_reader :sortable_options
        class_variable_set "@@sortable_options", options

        named_scope :column_sort, lambda { |order, direction|
          { :order => sanitize_order_and_direction(order, direction) }
        }
      end

      def sortable_columns
        @sortable_columns ||= sortable_options[:columns].map{ |c| SortableColumn.new(c) }
      end

      def sanitize_order_and_direction(order, direction)
        order ||= "updated_at"
        direction = direction ? direction.upcase : "DESC"

        default_order = sortable_options[:default_order] || columns.first.name
        default_direction = sortable_options[:default_direction] || "DESC"

        #FIXME joins columns
        order = default_order unless columns.map(&:name).include?(order)
        direction = default_direction unless %w{ ASC DESC }.include?(direction)
 
        "#{ order } #{ direction }"
      end
    end
  end

  class SortableColumn #:nodoc:
    attr_reader :content, :name, :order, :no_sort

    def initialize(column) #:nodoc:
      case column
      when Symbol
        @content = column
        @name = column.to_s.humanize
        @order = column.to_s
      when Hash
        @content = column[:content]
        @name = column[:name] || column[:content] && column[:content].is_a?(Symbol) && column[:content].to_s.humanize || ""
        @order = column[:order] || column[:content] && column[:content].is_a?(Symbol) && column[:content].to_s || ""
        @no_sort = column[:no_sort]
      end
    end

    def no_sort?
      ! @no_sort.nil?
    end

    def data(helper, object) #:nodoc:
      case content
      when Symbol
        object.send content
      when Proc
        content.call(helper, object)
      end
    end
  end
end
