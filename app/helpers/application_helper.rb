# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include ResourcesHelper
  include ContentsHelper
  include MenuBoxHelper
  include SortableHelper
  include StagesHelper
  include TagsHelper

  # Get title in this order:
  # 1. string argument 
  # 2. @title instance variable
  # 3. Title based on variables set by the Controller
  # 4. <tt>controller.controller_name</tt> - <tt>site.name</tt>
  #
  # Options:
  # <tt>append_site_name</tt>:: Append the Site name to the title, ie, "Title - Example Site". Defaults to <tt>false</tt>
  #
  def title(new_title = "", options = {})
    title = if new_title.present?
              new_title
            elsif @title
              @title
            elsif @contents
              container ?
                t(:other_in_container, :scope => controller.controller_name.singularize) :
                t(:other, :scope => controller.controller_name.singularize)
            elsif @resources
                t(:other, :scope => controller.controller_name.singularize)
            elsif @resource
              if @resource.new_record?
                t(:new, :scope => @resource.class.to_s.underscore)
              elsif controller.action_name == 'edit' || @resource.errors.any?
                t(:editing, :scope => @resource.class.to_s.underscore)
              else
                @resource.title
              end
            else
              controller.controller_name.titleize
            end
    title << " - #{ site.name }" if options[:append_site_name]
            
    sanitize(title)
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

  def link_author(resource)
    author = resource.respond_to?(:author) && resource.author ?
               resource.author :
               Anonymous.current
    link_agent(author)
  end

  def link_agent(agent)
    returning "" do |html|
      html << link_to(image_tag(icon_image(agent), 
                                :alt => "#{ sanitize agent.name } icon", 
                                :title => sanitize(agent.name),
                                :class => 'icon'))
      html << ( agent.is_a?(SingularAgent) ?
        agent.name :
        link_to(sanitize(agent.name), polymorphic_path(agent)))
    end
  end

  def link_icon(resource)
    link_to(image_tag(icon_image(resource),
                      :alt => "#{ resource.class } icon",
                      :title => resource.class.to_s,
                      :class => 'icon'), resource)
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
  #
  # Options:
  # size:: Size of the icon. Defaults to 16 pixels.
  def icon_image(object, options = {})
    options[:size] ||= 16

    if object.is_a?(Entry)
      icon_image object.content
    elsif object.is_a?(Logotype)
      "#{ formatted_polymorphic_path([object, object.format]) }?thumbnail=#{ options[:size] }"
    elsif ! object.new_record? &&
          object.respond_to?(:format) &&
          object.respond_to?(:attachment_options) && 
          object.attachment_options[:thumbnails].keys.include?(:icon) &&
          object.thumbnails.find_by_thumbnail('icon')
      "#{ formatted_polymorphic_path([object, object.format]) }?thumbnail=icon"
    elsif object.respond_to?(:logotype) && object.logotype
      icon_image object.logotype
    else
      file = object.respond_to?(:mime_type) && object.mime_type ?
        object.mime_type.to_s.gsub(/[\/\+]/, '-') : 
        object.class.to_s.underscore
      file = "icons/#{ options[:size] }/#{ file }.png"

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
      html << '<i>' + link_to(t(:preview_current, :scope => content.class.to_s.underscore), formatted_polymorphic_path([ content, content.format ])) + '</i>'
      html << '</p>'
    end
  end

  # Prints an atom <tt>link</tt> header for feed autodiscovery.
  # Use it in partials:
  #   atom_link(container, Content.new)
  # You must have <tt>yield(:headers)</tt> in your layout
  def atom_link_header(*args)
    content_for :headers, "<link href=\"#{ polymorphic_url(args) }.atom\" rel=\"alternate\" title=\"#{ title }\" type=\"application/atom+xml\" />"
  end
end

