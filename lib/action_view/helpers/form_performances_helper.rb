module ActionView #:nodoc:
  module Helpers #:nodoc:
    # Provides methods for Performances forms
    module FormPerformancesHelper
      # Render Performances form for object
      #
      # Object must be a Stage
      #
      # Options:
      # roles:: Array of Roles available
      def performances(object, options = {})
        InstanceTag.new(object, :performances, self, options.delete(:object)).to_performances_tag(options)
      end
    end

    class InstanceTag #:nodoc:
      include FormPerformancesHelper

      def to_performances_tag(options)
        options[:roles] = object.class.roles + Role.without_stage_type

        # TODO
        # raise "#{ object } isn't a Stage" unless object.acts_as_stage?

        @template_object.render :partial => "stages/performances_form", 
                                :locals => { :stage => object,
                                             :stage_name => object_name,
                                             :roles => options[:roles] }
      end
    end

    class FormBuilder #:nodoc:
      def performances(options = {})
        @template.performances(@object_name, options.merge(:object => @object))
      end
    end
  end
end
