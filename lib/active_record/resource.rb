require 'atom/entry'

module ActiveRecord #:nodoc:
  # A Resource is a model that supports, at least, CRUD operations. 
  # As consecuence, it can be imported/exported in several Content Types, which include:
  #
  # XML:: text document encoded using Extensible Markup Language (XML). These include XHTML, Atom and RSS.
  # YAML:: text document encoded using YAML Ain't a Markup Language (YAML). These include JSON.
  # HTML encoding:: usually the result of HTML Forms, uses application/x-www-form-urlencoded or multipart/form-data
  # Raw:: binary data
  #
  # Include this functionality in your models using ActsAsMethods#acts_as_resource
  module Resource
    class << self
      # Return the first Resource class supporting this Content Type
      def class_supporting(content_type)
        mime_type = content_type.is_a?(Mime::Type) ?
          content_type :
          Mime::Type.lookup(content_type)
        
        classes.each do |klass|
          return klass if klass.mime_types.include?(mime_type)
        end
        nil
      end

      def included(base) # :nodoc:
        # Fake named_scope to ActiveRecord instances that haven't children
        base.named_scope :parents, lambda  { {} }
        base.extend ActsAsMethods
      end
    end

    module ActsAsMethods
      # Provides an ActiveRecord model with Resource capabilities
      #
      # Options:
      # * <tt>:mime_types</tt> - array of Mime::Type supported by this Resource.
      # * <tt>:has_media</tt> - this Content has attachment data. Supported plugins: AttachmentFu (<tt>:attachment_fu</tt>)
      # * <tt>:param</tt> - used to find and build the URLs. Defaults to <tt>:id</tt>
      # * <tt>:disposition</tt> - specifies whether the Resource will be shown inline or as attachment (see Rails send_file method). Defaults to :attachment
      # * <tt>:per_page</tt> - number of Resources shown per page, using will_pagination plugin. Defaults to 9
      # * <tt>:delegate_content_types</tt> - allow using ActiveRecord::Resource.class_supporting for finding the class most suitable for some media. This is useful if you have a generic model for Attachments, but specific files like images or audios should be managed by other classes. Defaults to <tt>false</tt>
      #
      def acts_as_resource(options = {})
        ActiveRecord::Resource.register_class(self)

        options[:param]       ||= :id
        options[:disposition] ||= :attachment
        options[:per_page]    ||= 9
        options[:delegate_content_types] ||= false

        named_scope :parents, lambda {
          column_names.include?('parent_id') ?
          { :conditions => { :parent_id => nil } } :
          {}
        }

        if options[:has_media] == :attachment_fu
          alias_attribute :media, :uploaded_data
        end

        unless acts_as?(:agent)
          attr_protected :author, :author_id, :author_type
        end

        cattr_reader :resource_options
        class_variable_set "@@resource_options", options

        cattr_reader :per_page
        class_variable_set "@@per_page", options[:per_page]

        acts_as_sortable

        extend  ClassMethods
        include InstanceMethods
      end

      # Find with params
      def find_with_param(*args)
        if respond_to?(:resource_options)
          send "find_by_#{ resource_options[:param] }", *args
        else
          find *args
        end
      end
    end

    module ClassMethods
      # Array of Mime objects accepted by this Content
      def mime_types
        Array(resource_options[:mime_types]).map{ |m| Mime.const_get(m.to_sym.to_s.upcase) }
      end

      # List of comma separated content types accepted for this Content
      def accepts
        list = mime_types.map{ |m| Array(m.to_s) + m.instance_variable_get("@synonyms") }.flatten
        list << "application/atom+xml;type=entry" if self.respond_to?(:from_atom)
        list.uniq.join(", ")
      end
    end

    module InstanceMethods
      # Returns the mime type for this Content instance. 
      # Example: Mime::XML
      def mime_type
        return nil unless respond_to?(:content_type)

        mime_type = Mime::Type.lookup(content_type)
        # mime_type must be a registered Mime::Type
        mime_type.instance_variable_get("@symbol") ?
          mime_type :
          nil
      end

      # Returns the Mime::Type symbol for this content
      def format
        mime_type ? mime_type.to_sym : nil
      end
      
      # Method useful for icon files
      #
      # If the Content has a Mime Type, return it scaped with '-' 
      #   application/jpg => application-jpg
      # else, return the underscored class name:
      #   photo
      def mime_type_or_class_name
        mime_type ? mime_type.to_s.gsub(/[\/\+]/, '-') : self.class.to_s.underscore
      end

      # Define to_param method with acts_as_resource param option
      def to_param
        send(self.class.resource_options[:param]).to_s
      end
    end
  end
end
