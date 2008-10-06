# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include ContentsHelper
  include MenuBoxHelper
  include SortableHelper

  # Get title in this order:
  # 1. string argument 
  # 2. class variable +@title+, typically assigned in the Controller
  # 3. +current_site[:name]+
  def title(new_title = "" )
    sanitize(new_title.any? ? new_title : ( @title || current_site[:name] ))
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

  def link_icon_and_name_with_author(entry)
    entry.agent.login
  end

  # The path to the icon image for this object.
  #
  # If the object is a Entry, returns the path for the icon of its content. 
  # If it is an image, to the icon thumbnail. 
  #
  # Otherwise, it looks for a file based on mime type or, if the object 
  # hasn't mime type, the class name tableized.
  #
  # Finally, it first looks for the icon file in /public/images/icons, and at last 
  # in /public_assets/cmsplugin/images/icons
  def icon_image(object)
    if object.is_a?(Entry)
      icon_image object.content
    elsif ! object.new_record? &&
          object.respond_to?(:mime_type) &&
          object.respond_to?(:thumbnails) && 
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
end

