# Basic Helper Methods
module ActionView #:nodoc:
  module Helpers #:nodoc:
    module StationHelper
      # Get title in this order:
      # 1. string argument 
      # 2. @title instance variable
      # 3. Title based on variables set by the Controller
      # 4. <tt>controller.controller_name</tt> - <tt>current_site.name</tt>
      #
      # Options:
      # <tt>append_site_name</tt>:: Append the Site name to the title, ie, "Title - Example Site". Defaults to <tt>false</tt>
      #
      def title(new_title = "", options = {})
        title = if new_title.present?
                  new_title.dup
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
        title << " - #{ current_site.name }" if options[:append_site_name]
                
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

      # Prints an atom <tt>link</tt> header for feed autodiscovery.
      # Use it in partials:
      #   atom_link(container, Content.new)
      # You must have <tt>yield(:headers)</tt> in your layout
      def atom_link_header(*args)
        content_for :headers, "<link href=\"#{ polymorphic_url(args) }.atom\" rel=\"alternate\" title=\"#{ title }\" type=\"application/atom+xml\" />"
      end
    end
  end
end

