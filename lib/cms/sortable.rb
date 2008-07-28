module CMS 
  # Container(s) are models receiving Content(s) posted by Agent(s)
  module Sortable
    def self.included(base) #:nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      # Provides an ActiveRecord model with Sort capabilities
      def acts_as_sortable(options = {})
        options[:columns] ||= 
          self.columns.map{ |c| { :name => c.name.humanize, :content => c.name.to_sym } }

        cattr_reader :sortable_options
        class_variable_set "@@sortable_options", options

        named_scope :column_sort, lambda { |order, direction|
          { :order => sanitize_order_and_direction(order, direction) }
        }
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
end
