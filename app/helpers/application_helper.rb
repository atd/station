# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include MenuBoxHelper
  include SortableHelper

  # Get title in this order:
  # 1. class variable +@title+, typically assigned in the Controller
  # 2. string argument 
  # 3. +current_site[:name]+
  def title(title = "" )
    @title || (title.any? ? title : current_site[:name])
  end

  # Renders @notification_area@ div if there is a flash entry for types: 
  # @:valid@, @:error@, @:warning@ and @:info@
  def notification_area
    returning '<div id="notification_area">' do |html|
      for type in %w{ valid error warning info}
        next if flash[type.to_sym].blank?
        html << "<div class=\"#{ type }_action\">#{ flash[type.to_sym] }</div>"
      end
      html << "</div>"
    end 
  end

  def link_icon_and_name_with_author(post)
    post.agent.login
  end

  # The path to the icon image for this object.
  #
  # If the object is a Post, returns the path for the icon of its content. 
  # If it is an image, to the icon thumbnail. 
  #
  # Otherwise, it looks for a file based on mime type or, if the object 
  # hasn't mime type, the class name tableized.
  #
  # Finally, it first looks for the icon file in /public/images/icons, and at last 
  # in /public_assets/cmsplugin/images/icons
  def icon_image(object)
    if object.is_a?(Post)
      icon_image object.content
    elsif object.respond_to?(:thumbnails) && 
          object.respond_to?(:mime_type) && 
          ! object.new_record?
      "#{ formatted_polymorphic_path([object, object.mime_type.to_sym]) }?thumbnail=icon"
    else
      file = object.respond_to?(:mime_type) && object.mime_type ?
        object.mime_type.to_s.gsub(/[\/\+]/, '-') : 
        object.class.to_s.underscore
      file = "icons/#{ file }.png"

      File.exists?("#{ RAILS_ROOT }/public/images/#{ file }") ?
        image_path(file) :
        image_path(file, :plugin => 'cmsplugin')
    end
  end

  # Contents menu

  def new_content_button
    returning "" do |html|
      html << "<div id=\"content_new_top\" class=\"block_white_top\">» #{ "New Post".t } </div>"
      html << "<div id=\"content_new_center\" class=\"block_white_center\">"
      for content_type in current_container.accepted_content_types.sort{ |x, y| x.to_s <=> y.to_s }
        html << link_to("New #{ content_type.to_s.humanize.singularize }".t, polymorphic_path([ current_container.to_ppath, content_type.to_class.new ]), {:class => "action add" })
      end
      html << "</div>"
      html << "<div id=\"content_new_bottom\" class=\"block_white_bottom\"></div><br />"
    end
  end

  def contents_menu_separator
    '<hr class="separator" />'
  end

  def contents_menu
    menu = ""
    for content in CMS.content_classes.sort{ |a, b| a.to_s.t(a.to_s.pluralize, 99) <=> b.to_s.t(b.to_s.pluralize, 99) }
     #menu << "<span class=\"content_unit button\">"+link_to("» #{ content.collection.to_s.humanize }", send("#{ content.to_s.tableize }_url") , {:id => "content_unit_#{ content.collection }_link", :class => "content_unit_link" })
      #menu << "</span>"
     content_link = polymorphic_path([ @container.to_ppath, content.new ].compact)
     menu << link_to("<span id=\"content_link_#{ content.collection }\"> » #{ content.to_s.t(content.to_s.pluralize, 99) } </span>", content_link, {:class => "content_link inactive button" })
     end
   menu
  end

  def content_info(post = nil)
    html_return =  "<div id=\"content_info_top\" class=\"block_white_top\">» #{ "Post Info".t } </div>"
    html_return << "<div id=\"content_info_center\" class=\"block_white_center\">#{ render(:partial => "posts/post_details") if post }</div>"
    html_return << "<div id=\"content_info_bottom\" class=\"block_white_bottom\"></div>"
    html_return
  end
end

