module ActionView #:nodoc:
  module Helpers #:nodoc:
    module TagsHelper
      def tags(taggable)
        returning "" do |html|
          html << "<div id=\"#{ dom_id(taggable) }_tags\" class=\"tags\">"
          if taggable.tags.any?
            html << "<strong>#{ t('tag.other') }</strong>: "
            html << taggable.tags.map { |t| 
#                     link_to(t.name, tag_path(t), :rel => "tag") 
                      sanitize t.name
                    }.join(", ")
          end
          html << '</div>'
        end
      end
    end
  end
end
