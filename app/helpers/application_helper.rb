# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include ContentsHelper
  include MenuBoxHelper
  include SortableHelper
  include StagesHelper

  # Get title in this order:
  # 1. string argument 
  # 2. class variable <tt>@title</tt>, typically assigned in the Controller
  # 3. <tt>current_site[:name]</tt>
  def title(new_title = "" )
    sanitize(new_title.any? ? new_title : ( @title || current_site[:name] ))
  end

  # Renders notification_area div if there is a flash entry for types: 
  # <tt>:valid</tt>, <tt>:error</tt>, <tt>:warning</tt> and <tt>:info</tt>
  def notification_area
    returning '<div id="notification_area">' do |html|
      for type in %w{ valid error warning info}
        next if flash[type.to_sym].blank?
        html << "<div class=\"#{ type }_action\">#{ flash[type.to_sym] }</div>"
      end
      html << "</div>"
    end 
  end

  def link_icon_and_name_with_author(entry)
    entry.agent.login
  end

  # The path to the icon image for the object.
  #
  # If the object is a Entry, returns the path for the icon of its Content. 
  #
  # If the object is an image, and it's already saved, it returns the path 
  # to the icon thumbnail. 
  #
  # Else, it builds the file name based on mime type or, if the object 
  # hasn't mime type, the class name tableized.
  #
  #   icon_image(attachment) #=> .../application-pdf.png
  #   icon_image(xhtml_text) #=> .../xhtml_text.png
  #
  # Finally, it first looks for the icon file in /public/images/icons, 
  # and at last in /public_assets/cmsplugin/images/icons
  def icon_image(object)
    if object.is_a?(Entry)
      icon_image object.content
    elsif object.is_a?(Logotype)
      "#{ formatted_polymorphic_path([object, object.format]) }?thumbnail=48"
    elsif ! object.new_record? &&
          object.respond_to?(:mime_type) &&
          object.respond_to?(:attachment_options) && 
          object.attachment_options[:thumbnails].keys.include?(:icon) &&
          object.thumbnails.find_by_thumbnail('icon')
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

  # Show a preview of content if it's not null and it's not a new record. 
  # Preview consists of icon_image and a link to the content
  def preview(content)
    return "" unless content && ! content.new_record?

    returning "" do |html|
      html << '<p>'
      html << link_to(image_tag(icon_image(content)), formatted_polymorphic_path([ content, content.format ]))
      html << '<br />'
      html << '<i>' + link_to("Preview current #{ content.class.to_s.humanize }".t, formatted_polymorphic_path([ content, content.format ])) + '</i>'
      html << '</p>'
    end
  end
end

