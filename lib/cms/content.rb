module CMS
  # A Content is a unit of information suitable to be published online.
  # Examples of contents are texts, images, events, URIs
  #
  # Content(s) are posted by Agent(s) to Container(s), resulting in Post(s)
  module Content
    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      # Provides an ActiveRecord model with Content capabilities
      #
      # Content(s) are posted by Agent(s) to Container(s), creating Post(s)
      #
      # Options:
      # * <tt>:collection</tt> - this Content has an particular collection name, (ex. blog for articles, calendar for events, etc..)
      # * <tt>:mime_types</tt> - array of Mime Types supported by this content. Defaults to "application/atom+xml;type=entry"
      # * <tt>:mime_type_images</tt> - specifies if this content has images (icons and logos) per Mime Type or only a Class image. Defaults to false (Class image)
      # * <tt>:has_attachment</tt> - this Content has attachment data
      # * <tt>:disposition</tt> - specifies whether the Content will be shown inline or as attachment (see Rails send_file method). Defaults to :attachment
      # * <tt>:per_page</tt> - number of contents shown per page, using will_pagination plugin. Defaults to 9
      #
      def acts_as_content(options = {})
        cattr_reader :collection,
                     :mime_types,
                     :mime_type_images,
                     :has_attachment,
                     :disposition,
                     :per_page

        options[:collection]       ||= self.to_s.tableize.to_sym
        #FIXME: should this be the default mime type??
        options[:mime_types]       ||= "application/atom+xml;type=entry"
        options[:mime_type_images] ||= false
        options[:has_attachment]   ||= false
        options[:disposition]      ||= :attachment
        options[:per_page]         ||= 9

        # Convert options to class variables
        options.each_pair do |var, value|
          class_variable_set "@@#{ var }".to_sym, value
        end

        has_many :posts, :as => :content, :class_name => "CMS::Post"

        include CMS::Content::InstanceMethods
      end

      # Icon image path
      def icon_image
        'icons/' + self.to_s.underscore.concat(".png")
      end
    end

    module InstanceMethods
      # Returns the mime type for this Content instance
      def mime_type
        respond_to?("content_type") ? Mime::Type.lookup(content_type) : nil
      end

      # Can this <tt>agent</tt> read this Content?
      # True if there exists a Post for this Content that can be read by <tt>agent</tt> 
      def read_by?(agent = nil)
        for p in posts
          return true if p.read_by?(agent)
        end
        false
      end

      # Path to a logo image for this Content
      def logo_image
        "logos/#{ image_file_name }.png"
      end

      # Path to an icon image for this Content
      def icon_image
        "icons/#{ image_file_name }.png"
      end

      protected

      def image_file_name #:nodoc:
        mime_type_images && mime_type ? mime_type.to_s.gsub(/[\/\+]/, '-') : self.class.to_s.underscore
      end
    end
  end
end
