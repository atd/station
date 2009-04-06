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
                t(:other_in_container, :scope => controller.controller_name.singularize, :container => container.name) :
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
  # <tt>:valid</tt>, <tt>:error</tt>, <tt>:warning</tt>, <tt>:info</tt>, <tt>:notice</tt> and <tt>:success</tt>
  def notification_area
    returning '<div id="notification_area">' do |html|
      for type in %w{ valid error warning info notice success}
        next if flash[type.to_sym].blank?
        html << "<div class=\"#{ type }\">#{ flash[type.to_sym] }</div>"
      end
      html << "</div>"
    end 
  end

  # Prints link_icon_and_name of the resource author. If the resource hasn't author, uses Anonymous user.
  def link_author(resource, options = {})
    author = resource.respond_to?(:author) && resource.author ?
               resource.author :
               Anonymous.current
    link_icon_and_name(author, options)
  end

  # Prints the icon and name for the resource. If the resource is a SingularAgent, no link is printed.
  def link_icon_and_name(resource, options = {})
    returning "" do |html|
      if resource.is_a?(SingularAgent)
        html << image_tag(icon_image(resource, options), 
                                     :alt => "[ #{ sanitize resource.name } icon ]",
                                     :title => sanitize(resource.name),
                                     :class => 'icon')
        html << resource.name
      else
        html << link_to(image_tag(icon_image(resource, options), 
                                  :alt => "[ #{ sanitize resource.name } icon ]",
                                  :title => sanitize(resource.name),
                                  :class => 'icon'), polymorphic_path(resource))
        html << link_to(sanitize(resource.name), polymorphic_path(resource))
      end
    end
  end

  # Prints the icon_image for resource, linking it to the resource path.
  #
  # Options:
  # url:: The URL that will be used in the link. Defaults to the resource.
  def link_icon(resource, options = {})
    url = options.delete(:url) || resource

    link_to(image_tag(icon_image(resource, options),
                      :alt => "#{ resource.respond_to?(:name) ? sanitize(resource.name) : resource.class } icon",
                      :title => (resource.respond_to?(:title) ? sanitize(resource.title) : resource.class.to_s),
                      :class => 'icon'), url)
  end

  # The path to the icon image for the object.
  #
  # If the object is a Logo, returns the path for the Logo data.
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
  # Finally, it looks for the icon file in /public/images/models, 
  # and at last in /public_assets/cmsplugin/images/models
  #
  # Options:
  # size:: Size of the icon. Defaults to 16 pixels.
  def icon_image(object, options = {})
    options[:size] ||= 16

    if object.is_a?(Logo)
      "#{ formatted_polymorphic_path([object, object.format]) }?thumbnail=#{ options[:size] }"
    elsif ! object.new_record? &&
          object.respond_to?(:format) &&
          object.respond_to?(:attachment_options) && 
          object.attachment_options[:thumbnails].keys.include?(:icon) &&
          object.thumbnails.find_by_thumbnail('icon')
      "#{ formatted_polymorphic_path([object, object.format]) }?thumbnail=icon"
    elsif object.respond_to?(:logo) && object.logo
      icon_image object.logo, options
    else
      file = object.respond_to?(:mime_type) && object.mime_type ?
        object.mime_type.to_s.gsub(/[\/\+]/, '-') : 
        object.class.to_s.underscore
      file = "models/#{ options[:size] }/#{ file }.png"

      File.exists?("#{ RAILS_ROOT }/public/images/#{ file }") ?
        image_path(file) :
        image_path(file, :plugin => 'cmsplugin')
    end
  end

  # Show a preview of content if it's not null and it's not a new record. 
  # Preview consists of icon_image and a link to the content
  def preview(content, options = {})
    return "" unless content && ! content.new_record?

    options[:size] ||= 64

    returning "" do |html|
      html << '<p>'
      html << link_to(image_tag(icon_image(content, options.dup)), formatted_polymorphic_path([ content, content.format ]))
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

