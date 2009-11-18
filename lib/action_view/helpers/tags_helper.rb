module ActionView #:nodoc:
  module Helpers #:nodoc:
    module TagsHelper
      def tags(taggable)
        returning "" do |html|
          html << "<div id=\"#{ dom_id(taggable) }_tags\" class=\"tags\">"
          if taggable.tags.any?
            html << "<strong>#{ t('tag.other') }</strong>: "
            html << taggable.tags.map { |t| 
                     link_to(t.name, t, :rel => "tag") 
                    }.join(", ")
          end
          html << '</div>'
        end
      end

      # Draw the tag cloud of container
      def tag_cloud(container, options = {})
        options[:count] ||= 20

        tags = container.tags.popular.all(:limit => options[:count]).sort{ |x, y| x.name <=> y.name }

        tags.any? ? render(:partial => 'tags/cloud', :object => tags) : ""
      end
    end
  end
end
