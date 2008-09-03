module SortableHelper
  # Renders Sortable List table
  #
  # list:: an Array of objects to be listed
  # list_class:: the class that acts_as_sortable. It defines sortable Columns and the path to the list queries
  #
  # Available options are:
  # path:: Array of objects that will be appended to polymorphic_path to build the list path. Useful for nested resources.
  # append:: Append string to sortable requests. Example: <tt>"&q=#{ params[:q] }"</tt>
  # table_class:: Class of the html +table+
  # table_id:: ID of the html +table+
  # actions:: Actions to be performed on object. Defaults to <tt>[ :show, :edit, :delete ]</tt>
  # icon_path:: Path to action icons (not implemented)
  def sortable_list(list, list_class, options = {})
    list_path = (Array(options[:path]) + Array(list_class.new)).compact
    options[:table_class] ||= "#{ list_class.to_s.tableize }_list"
    options[:table_id] ||= "#{ list_class.to_s.tableize }_list"
    options[:actions] ||= [ :show, :edit, :delete ]

    returning "" do |html|
      html << "<table class=\"#{ options[:table_class].to_s }\" id=\"#{ options[:table_id].to_s }\">"
      html << '<tr>'
      for column in list_class.sortable_columns
        html << '<th>'
        unless column.no_sort?
          html << link_to("", "#{ polymorphic_path(list_path) }?order=#{ column.order }&direction=desc#{ options[:append] }", :class => "sortable desc" )
          html << link_to("", "#{ polymorphic_path(list_path) }?order=#{ column.order }&direction=asc#{ options[:append] }", { :class => "sortable asc" })
        end
        html << "<label>#{ column.name.t }</label>"
        html << "</th>"
      end
      html << '<th class="list_actions">'
      html << '</th>'
      html << '</tr>'
      for object in list
        html << "<tr class=\"style_#{ cycle('0', '1') }\">"
        for column in list_class.sortable_columns
          html << "<td>#{ sanitize column.data(self, object).to_s }</td>"
        end

        html << '<td class="list_actions">'
        actions = options[:actions].clone
        # Show
        html << link_to(image_tag("actions/show.png", :alt => "Show".t, :plugin => 'cmsplugin'), polymorphic_path(object)) if actions.delete(:show)

        # Delete
        delete_html = link_to(image_tag("actions/delete.png", :alt => "Delete".t, :plugin => 'cmsplugin'), polymorphic_path(object), :confirm => 'Are you sure?'.t, :method => :delete) if actions.delete(:delete)

        # Rest of actions
        actions.each do |a|
          html << link_to(image_tag("actions/#{ a }.png", :alt => a.to_s.humanize.t, :plugin => 'cmsplugin'), send("#{ a }_polymorphic_path", object))
        end

        html << delete_html
        html << '</td>'
        html << '</tr>'
      end
      html << '</table>'
    end
  end
end
