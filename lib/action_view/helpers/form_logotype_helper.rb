module ActionView
  module Helpers
    # Provides methods for Logotypable forms
    module FormLogotypeHelper
      # Render Logotype file field and preview for Logotypable models
      #
      # Object must be Logotypable
      #
      # Options:
      # title:: Title of the form
      def logotype(object, options = {})
        InstanceTag.new(object, :logotype, self, options.delete(:object)).to_logotype_tag(options)
      end
    end

    class InstanceTag #:nodoc:
      include FormLogotypeHelper

      def to_logotype_tag(options)
        options[:title] ||= I18n.t(:logotype, :count => 1)

        # TODO
        # raise "#{ object } isn't Logotypable" unless object.acts_as_logotypable?

        @template_object.render :partial => "logotypables/logotype_form", 
                                :locals => { :logotypable => object,
                                             :logotypable_name => object_name, 
                                             :title => options[:title] }
      end
    end

    class FormBuilder #:nodoc:
      def logotype(options = {})
        @template.logotype(@object_name, options.merge(:object => @object))
      end
    end
  end
end
