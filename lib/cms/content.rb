require 'atom/entry'

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
      # * <tt>:named_collection</tt> - this Content has an particular collection name, (ex. blog for articles, calendar for events, etc..)
      # * <tt>:atompub_mime_types</tt> - array of Mime Types accepted for this Content via AtomPub. Defaults to "application/atom+xml;type=entry"
      # * <tt>:mime_type_images</tt> - specifies if this content has images (icons and logos) per Mime Type or only a Class image. Defaults to false (Class image)
      # * <tt>:has_media</tt> - this Content has attachment data. Supported plugins: attachment_fu (<tt>:attachment_fu</tt>)
      # * <tt>:disposition</tt> - specifies whether the Content will be shown inline or as attachment (see Rails send_file method). Defaults to :attachment
      # * <tt>:per_page</tt> - number of contents shown per page, using will_pagination plugin. Defaults to 9
      #
      def acts_as_content(options = {})
        #FIXME: should this be the default mime type??
        options[:atompub_mime_types] ||= "application/atom+xml;type=entry"
        options[:mime_type_images]   ||= false
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
          alias_method_chain :create, :cms_params_filter
        end

        include CMS::Content::InstanceMethods
      end

      # Returns the symbol for a set of Contents of this item
      # e.g. <tt>:articles</tt> for Article
      def collection
        self.to_s.tableize.to_sym
      end

      # Returns the word for a named collection of this item
      # a.g. <tt>"Gallery"</tt> for Photo
      def named_collection
        content_options[:named_collection] || collection.to_s.humanize
      end
      
      # Icon image path
      def icon_image
        'icons/' + self.to_s.underscore.concat(".png")
      end

      protected

      # Introduce filters for parameters in create chain
      def create_with_cms_params_filter(params) #:nodoc:
        create_without_cms_params_filter cms_params_filter(params)
      end

      # Filter Content parameters:
      # If there is Atom Entry data, extract information from the Entry to parameters
      # If there is raw post data, convert it to suitable plugin
      def cms_params_filter(params) #:nodoc:
        if params[:atom_entry]
          atom_entry_filter(Atom::Entry.parse(params[:atom_entry]))
        elsif params[:raw_post]
          if content_options[:has_media] == :attachment_fu 
            media_attachment_fu_filter(params)
          end
        else
          params
        end
      end

      # Atom Entry filter
      # Extracts parameter information from an Atom Entry element
      #
      # Implement this in your class if you want AtomPub support in your Content
      def atom_entry_filter(atom_entry)
        {}
      end

      # Conversion from raw data to attachment_fu plugin
      def media_attachment_fu_filter(params) #:nodoc:
        file = Tempfile.new("file")
        file.write params[:raw_post]
        (class << file; self; end).class_eval do
          alias local_path path
          define_method(:content_type) { params[:content_type].dup.taint }
          define_method(:original_filename) { params[:filename].dup.taint }
        end
        { "uploaded_data" => file }
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
