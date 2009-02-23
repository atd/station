module ActionView #:nodoc:
  module Helpers # :nodoc:
    # Provides methods for Taggable forms
    module FormTagsHelper
      # Render text field for assigning Tags to object.
      #
      # Object must be Taggable
      #
      def tags(object, options = {})
        InstanceTag.new(object, :tags, self, options.delete(:object)).to_tags_tag(options)
      end
    end

    class InstanceTag #:nodoc:
      include FormTagsHelper

      def to_tags_tag(options)
        # TODO
        # raise "#{ object } isn't Taggable" unless object.acts_as_taggable?

        @template_object.render :partial => "taggables/tags_form", 
                                :locals => { :taggable => object,
                                             :taggable_name => object_name }
      end
    end

    class FormBuilder #:nodoc:
      def tags(options = {})
        @template.tags(@object_name, options.merge(:object => @object))
      end
    end
  end
end
