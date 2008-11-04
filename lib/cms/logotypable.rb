module CMS 
  # Logotypable ActiveRecord module
  module Logotypable
    class << self
      # Logotypable Classes
      def classes
        CMS.logotypables.map(&:to_class)
      end

      def included(base) #:nodoc:
        base.extend ClassMethods
      end
    end

    module ClassMethods
      # Provides an ActiveRecord model with Logos
      def acts_as_logotypable
        CMS.register_model self, :logotypable

        has_one :logotype, :as => :logotypable

        validates_associated :logotype

        after_save do |logotypable|
          logotypable.logotype.save! if logotypable.logotype
        end
      end
    end
  end
end
