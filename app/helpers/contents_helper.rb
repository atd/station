module ContentsHelper
  # Display buttons for add contents to current_container
  def new_content_button
    return "" unless current_container

    returning "" do |html|
      html << "<div id=\"content_new_top\" class=\"block_white_top\">» #{ "New Entry".t } </div>"
      html << "<div id=\"content_new_center\" class=\"block_white_center\">"
      for content_type in current_container.accepted_content_types.sort{ |x, y| x.to_s <=> y.to_s }
        html << link_to("New #{ content_type.to_s.humanize.singularize }".t, new_polymorphic_path([ current_container, content_type.to_class.new ]), {:class => "action add" })
      end
      html << "</div>"
      html << "<div id=\"content_new_bottom\" class=\"block_white_bottom\"></div><br />"
    end
  end

  # Separator
  def contents_menu_separator
    '<hr class="separator" />'
  end

  # Menu for container contents
  def contents_menu
    content_classes = ( current_container ?
      current_container.accepted_content_types.map(&:to_class) :
      CMS::ActiveRecord::Content.classes ).sort{ |a, b| 
      a.to_s.t(a.to_s.pluralize, 99) <=> b.to_s.t(b.to_s.pluralize, 99) 
    }

    returning "" do |html|
      for content in content_classes
     #menu << "<span class=\"content_unit button\">"+link_to("» #{ content.collection.to_s.humanize }", send("#{ content.to_s.tableize }_url") , {:id => "content_unit_#{ content.collection }_link", :class => "content_unit_link" })
      #menu << "</span>"
     content_link = polymorphic_path([ current_container, Entry.new ].compact) + "?content_type=#{ content.to_s.tableize }"
       html << link_to("<span id=\"content_link_#{ content.collection }\"> » #{ content.to_s.t(content.to_s.pluralize, 99) } </span>", content_link, {:class => "content_link inactive button" })
     end
    end
  end

  # Show info about the Content
  def content_info(entry = nil)
    entry ||= @entry

    html_return =  "<div id=\"content_info_top\" class=\"block_white_top\">» #{ "Details".t } </div>"
    html_return << "<div id=\"content_info_center\" class=\"block_white_center\">#{ render(:partial => "entries/entry_details", :locals => { :entry => entry }) if entry }</div>"
    html_return << "<div id=\"content_info_bottom\" class=\"block_white_bottom\"></div>"
    html_return
  end
end

