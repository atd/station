module CMS 
  module ActiveRecord
    # Logotypable ActiveRecord module
    module Logotypable
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

          validates_associated :logotype

          after_save do |logotypable|
            logotypable.logotype.save! if logotypable.logotype
          end
        end
      end
    end
  end
end
