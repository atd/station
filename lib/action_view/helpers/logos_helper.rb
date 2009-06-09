module ActionView #:nodoc:
  module Helpers #:nodoc:
    module LogosHelper
      # The path to the logo image for the resource.
      #
      # If the resource is a Logo, returns the path for the Logo data.
      #
      # If the resource is an image, and it's already saved, it looks for a thumbnail
      # of the same size of the logo. If it exists, it returns the path of the thumbnail. 
      #
      # Else, it builds the file name based on mime type or, if the object 
      # hasn't mime type, the class name tableized.
      #
      #   logo_image_path(attachment) #=> .../application-pdf.png
      #   logo_image_path(xhtml_text) #=> .../xhtml_text.png
      #
      # Finally, it looks for the image file in /public/images/models/:size/:mime-or-class.png
      #
      # Options:
      # size:: Size of the logo. Defaults to 16 pixels.
      def logo_image_path(resource, options = {})
        options[:size] ||= 16

        if resource.is_a?(Logo)
          resource.respond_to?(:public_filename) ?
            resource.public_filename(options[:size]) :
            polymorphic_path(resource, :format => resource.format, :thumbnail=> options[:size])
        elsif ! resource.new_record? &&
              resource.respond_to?(:format) &&
              resource.respond_to?(:attachment_options) && 
              resource.attachment_options[:thumbnails].keys.include?(options[:size].to_s) &&
              resource.thumbnails.find_by_thumbnail(options[:size].to_s)
          polymorphic_path(resource, :format => resource.format, :thumbnail => options[:size])
        elsif resource.respond_to?(:logo) && resource.logo
          logo_image_path(resource.logo, options)
        else
          file = resource.respond_to?(:mime_type) && resource.mime_type ?
            resource.mime_type.to_s.gsub(/[\/\+]/, '-') : 
            resource.class.to_s.underscore
          file = "models/#{ options[:size] }/#{ file }.png"

          image_path(file)
        end
      end

      # Prints an image_tag with the logo_image_path for the resource inside a div
      # Options:
      # title:: <tt>title</tt> attribute of the <tt>image_tag</tt>
      # alt:: <tt>alt</tt> attribute of the <tt>image_tag</tt>
      def logo(resource, options = {})
        options[:size] ||= 16
        url = options.delete(:url)
        alt = options.delete(:alt) || "[ #{ resource.respond_to?(:name) ? sanitize(resource.name) : resource.class } logo ]"
        title = options.delete(:title) || (resource.respond_to?(:title) ? sanitize(resource.title) : resource.class.to_s)

        returning "" do |html|
    #      html << "<div class=\"logo logo-#{ options[:size] }\">"

          image = image_tag(logo_image_path(resource, options),
                            :alt => alt,
                            :title => title,
                            :class => 'logo')

          html << link_to_if(url, image, url, :class => 'logo')

    #      html << '</div>'
        end
      end

      # The logotype is composed by the logo plus the name of the resource
      #
      # Uses the template in <tt>app/views/logoable/_logotype.html.erb</tt>
      #
      # Options:
      # spacer:: Separates logo and text
      # text:: Text besides the logo. Defaults to resource.name || resource.title || resource.class
      def logotype(resource, options = {})
        options[:spacer] ||= " "

        text = options.delete(:text) ||
          if resource.respond_to?(:name)
            sanitize resource.name
          elsif resource.respond_to?(:title)
            sanitize resource.title
          else
            t(:one, :scope => resource.class.to_s.underscore)
          end

        if options[:url]
          text = link_to(text, options[:url])
        end

        logo(resource, options) + options[:spacer] + text
      end

      def try_url(resource) #:nodoc:
        polymorphic_path(resource)
      rescue NoMethodError
        nil
      end

      # Prints and links the resource logo.
      #
      # Options:
      # url:: The URL that will be used in the link. Defaults to the resource.
      def link_logo(resource, options = {})
        options[:url] ||= try_url(resource)
        logo(resource, options)
      end

      # Prints and links the resource logotype.
      #
      # Options:
      # url:: The URL that will be used in the link. Defaults to the resource.
      def link_logotype(resource, options = {})
        options[:url] ||= try_url(resource)
        logotype(resource, options)
      end

      # Prints link_logotype of the resource's author. If the resource hasn't author, uses Anonymous user.
      def link_author(resource, options = {})
        author = resource.respond_to?(:author) && resource.author ?
                   resource.author :
                   Anonymous.current
        link_logotype(author, options)
      end

      # Show a preview of content if it's not null and it isn't a new record. 
      # Preview consists of link_logo to the content
      def preview(content, options = {})
        return "" unless content && ! content.new_record?

        options[:size] ||= 64
        options[:text] ||= t(:current, :scope => content.class.to_s.underscore)

        link_logotype(content, options)
      end
    end
  end
end
