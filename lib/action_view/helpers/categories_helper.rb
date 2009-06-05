module ActionView #:nodoc:
  module Helpers #:nodoc:
    module CategoriesHelper
      # Return a list of linked Categories, separated by <tt>,</tt>
      def categories(categorizable)
        returning "" do |html|
          html << "<div id=\"#{ dom_id(categorizable) }_categories\" class=\"categories\">"
          if categorizable.categories.any?
            html << "<strong>#{ t('category.other') }</strong>: "
            html << categorizable.categories.map{ |c|
                      link_to c.name, [ c.domain, c ]
                    }.join(', ')

          end
          html << '</div>'
        end
      end
    end
  end
end
