module ActionView #:nodoc:
  module Helpers #:nodoc:
    module CategoriesHelper
      # Return a list of linked Categories, separated by <tt>,</tt>
      def categories(item)
        item.categories.map{ |c|
          link_to c.name, [ c.domain, c ]
        }.join(', ')
      end
    end
  end
end
