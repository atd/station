module ActionView #:nodoc:
  module Helpers # :nodoc:
    # Provides methods for Categorizable forms
    module FormCategoriesHelper
      # Render checkboxes for assigning Categories to object.
      #
      # Object must be Categorizable
      #
      # Options:
      # domain:: The CategoriesDomain for Categories list. Defaults tu current_container || Site.current
      def categories(object, options = {})
        InstanceTag.new(object, :categories, self, options.delete(:object)).to_categories_tag(options)
      end
    end

    class InstanceTag #:nodoc:
      include FormCategoriesHelper

      def to_categories_tag(options)
        options[:domain] ||= @template_object.categories_domain

        # TODO
        # raise "#{ object } isn't Categorizable" unless object.acts_as_categorizable?

        @template_object.render :partial => "categorizables/categories_form", 
                                :locals => { :categorizable => object,
                                             :categorizable_name => object_name, 
                                             :domain => options[:domain] }
      end
    end

    class FormBuilder #:nodoc:
      def categories(options = {})
        @template.categories(@object_name, options.merge(:object => @object))
      end
    end
  end
end
