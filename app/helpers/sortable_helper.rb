module SortableHelper
  # Renders Sortable List table
  #
  # object_list:: an Array of objects to be listed
  # object_class:: the class that acts_as_sortable and defines sortable Columns
  #
  # Available options are:
  # path:: Array of objects that will be appended to polymorphic_path to build the collection path. Useful for nested resources.
  # append:: Append string to sortable requests. Example: <tt>"&q=#{ params[:q] }"</tt>
  # table_class:: Class of the html +table+
  # table_id:: ID of the html +table+
  # icon_path:: Path to action icons (not implemented)
  def sortable_list(object_list, object_class, options = {})
    object_path = (Array(options[:path]) + Array(object_class.new)).compact
    options[:table_class] ||= "#{ object_class.to_s.tableize }_list"
    options[:table_id] ||= "#{ object_class.to_s.tableize }_list"

    returning "" do |html|
      html << "<table class=\"#{ options[:table_class].to_s }\" id=\"#{ options[:table_id].to_s }\">"
      html << '<tr>'
      for column in object_class.sortable_columns
        html << '<th>'
        unless column.no_sort?
          html << link_to("", "#{ polymorphic_path(object_path) }?order=#{ column.order }&direction=desc#{ options[:append] }", :class => "sortable desc" )
          html << link_to("", "#{ polymorphic_path(object_path) }?order=#{ column.order }&direction=asc#{ options[:append] }", { :class => "sortable asc" })
        end
        html << "<label>#{ column.name.t }</label>"
        html << "</th>"
      end
      html << '<th class="list_actions">'
      html << '</th>'
      html << '</tr>'
      for object in object_list
        html << "<tr class=\"style_#{ cycle('0', '1') }\">"
        for column in object_class.sortable_columns
          html << "<td>#{ sanitize column.data(self, object).to_s }</td>"
        end
        html << '<td class="list_actions">'
        html << link_to(image_tag("actions/show.png", :alt => "Show".t, :plugin => 'cmsplugin'), polymorphic_path(object))
        html << link_to(image_tag("actions/edit.png", :alt => "Edit".t, :plugin => 'cmsplugin'), edit_polymorphic_path(object))
        html << link_to(image_tag("actions/delete.png", :alt => "Delete".t, :plugin => 'cmsplugin'), polymorphic_path(object), :confirm => 'Are you sure?'.t, :method => :delete)
        html << '</td>'
        html << '</tr>'
      end
      html << '</table>'
    end
  end
end
