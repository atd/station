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
      # * <tt>:atompub_mime_types</tt> - array of Mime Types accepted for this Content via AtomPub. Defaults to "application/atom+xml;type=entry"
      # * <tt>:mime_type_images</tt> - specifies if this content has images (icons and logos) per Mime Type or only a Class image. Defaults to false (Class image)
      # * <tt>:has_attachment</tt> - this Content has attachment data (typically, using one attachment plugin like attachment_fu)
      # * <tt>:atom_mapping</tt> - Hash mapping Content attributes to Atom Entry elements. Examples: { :body => :content }
      # * <tt>:disposition</tt> - specifies whether the Content will be shown inline or as attachment (see Rails send_file method). Defaults to :attachment
      # * <tt>:per_page</tt> - number of contents shown per page, using will_pagination plugin. Defaults to 9
      #
      def acts_as_content(options = {})
        options[:collection]         ||= self.to_s.tableize.to_sym
        #FIXME: should this be the default mime type??
        options[:atompub_mime_types] ||= "application/atom+xml;type=entry"
        options[:mime_type_images]   ||= false
        options[:has_attachment]     ||= false
        options[:atom_mapping]       ||= {}
        options[:disposition]        ||= :attachment
        options[:per_page]           ||= 9

        cattr_reader :content_options
        class_variable_set "@@content_options", options

        has_many :posts, :as => :content, :class_name => "CMS::Post"

        # Filter "create" method for Atom Mapping
        # With this filter, a new content can be crated from a Hash of
        # Atom Entry parameters
        # The Atom Entry may include different attibutes than the Content
        # (see atom_mapping option)
        #
        # This methods maps the appropriate attributes
        class << self
          alias_method_chain :create, :atom_mapping
        end unless options[:atom_mapping].blank?

        include CMS::Content::InstanceMethods
      end

      # Icon image path
      def icon_image
        'icons/' + self.to_s.underscore.concat(".png")
      end

      protected

      # Introduce atom_mapping filter in create chain
      def create_with_atom_mapping(params) #:nodoc:
        create_without_atom_mapping atom_mapping_filter(params)
      end

      # Map Atom Entry attributes to Content attributes
      def atom_mapping_filter(params) #:nodoc:
        return params if params.blank? || params[:atom_entry].blank?

        filtered_params = HashWithIndifferentAccess.new
        content_options[:atom_mapping].each_pair do |ar_attr, entry_attr|
          filtered_params[ar_attr] = params[entry_attr]
        end
        filtered_params
      end
    end

    module InstanceMethods
      # Returns the mime type for this Content instance. 
      # TODO: Works with attachment_fu
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
        content_options[:mime_type_images] && mime_type ? mime_type.to_s.gsub(/[\/\+]/, '-') : self.class.to_s.underscore
      end
    end
  end
end
