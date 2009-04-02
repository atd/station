module ActiveRecord #:nodoc:
  # Logoable ActiveRecord module
  module Logoable
    class << self
      def included(base) #:nodoc:
        base.extend ClassMethods
      end
    end

    module ClassMethods
      # Provides an ActiveRecord model with Logos
      #
      # Options:
      # class_name:: The model associated with this Logoable. Defaults to Logo.
      #
      def has_logo(options = {})
        ActiveRecord::Logoable.register_class(self)

        options[:class_name] ||= "Logo"

        has_one :logo, :as => :logoable,
                           :class_name => options[:class_name]

        send :attr_accessor, :_logo
        before_validation :_create_or_update_logo
        validates_associated :logo
        after_save :_save_logo!

        include InstanceMethods
      end

      alias_method :acts_as_logoable, :has_logo
    end

    module InstanceMethods
      private

      def _create_or_update_logo #:nodoc:
        return unless @_logo.present? && @_logo[:media].present?

        logo ?
          logo.attributes = @_logo :
          build_logo(@_logo)
      end

      def _save_logo! #:nodoc:
        return unless logo && logo.changed?

        logo.logoable = self if logo.new_record?

        logo.save!

        @_logo = nil
      end
    end
  end
end
