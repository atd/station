module CMS
  module SortableHelper
    def sortable_list(object_list, object_path)
      object_class = Array(object_path).last.class

      returning "" do |html|
        html << '<table>'
        html << '<tr>'
        for column in object_class.sortable_options[:columns]
          html << '<th>'
          unless column[:no_sort]
            html << link_to("", "#{ polymorphic_path(object_path) }?order=#{ column[:content] }&direction=desc", :class => "sortable desc" )
            html << link_to("", "#{ polymorphic_path(object_path) }?order=#{ column[:content] }&direction=asc", { :class => "sortable asc" })
          end
          html << "<label>#{ column[:name] }</label>"
          html << "</th>"
        end
        html << '<th class="list_actions">'
        html << '</th>'
        html << '</tr>'
        for object in object_list
          html << "<tr class=\"style_#{ cycle('0', '1') }\">"
          for column in object_class.sortable_options[:columns]
            html << "<td>#{ sanitize column_data(object, column).to_s }</td>"
          end
          html << '<td class="list_actions">'
          html << link_to(image_tag( "/images/cms/actions/show.png", {:alt => "Show".t} ), polymorphic_path(object))
          html << link_to(image_tag( "/images/cms/actions/edit.png", {:alt => "Edit".t} ), edit_polymorphic_path(object))
          html << link_to(image_tag( "/images/cms/actions/delete.png", {:alt => "Delete".t} ), polymorphic_path(object), :confirm => 'Are you sure?'.t, :method => :delete)
          html << '</td>'
          html << '</tr>'
        end
        html << '</table>'
      end
    end

    private

    def column_data(object, column) #:nodoc:
      case column[:content]
      when Symbol
        object.send(column[:content])
      when Proc
        column[:content].call(self, object)
      end
    end
  end
end
