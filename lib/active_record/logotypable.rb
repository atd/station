module ActiveRecord #:nodoc:
  # Logotypable ActiveRecord module
  module Logotypable
    include ActsAs

    class << self
      def included(base) #:nodoc:
        base.extend ClassMethods
      end
    end

    module ClassMethods
      # Provides an ActiveRecord model with Logos
      #
      # Options:
      # class_name:: The model associated with this Logotypable. Defaults to Logotype.
      #
      def acts_as_logotypable(options = {})
        ActiveRecord::Logotypable.register_class(self)

        options[:class_name] ||= "Logotype"

        has_one :logotype, :as => :logotypable,
                           :class_name => options[:class_name]

        send :attr_accessor, :_logotype
        before_validation :_create_or_update_logotype
        validates_associated :logotype
        after_save :_save_logotype!

        include InstanceMethods
      end
    end

    module InstanceMethods
      private

      def _create_or_update_logotype #:nodoc:
        return unless @_logotype.present? && @_logotype[:media].present?

        logotype ?
          logotype.attributes = @_logotype :
          build_logotype(@_logotype)
      end

      def _save_logotype! #:nodoc:
        return unless logotype && logotype.changed?

        logotype.logotypable = self if logotype.new_record?

        logotype.save!

        @_logotype = nil
      end
    end
  end
end
