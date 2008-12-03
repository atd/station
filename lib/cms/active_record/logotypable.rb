module CMS 
  module ActiveRecord
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
        def acts_as_logotypable
          CMS::ActiveRecord::Logotypable.register_class(self)

          has_one :logotype, :as => :logotypable

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
          return unless @_logotype

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
end
