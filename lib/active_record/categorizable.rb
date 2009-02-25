module ActiveRecord #:nodoc:
  # Categorizable ActiveRecord module
  module Categorizable
    class << self
      def included(base) #:nodoc:
        base.extend ClassMethods
      end
    end

    module ClassMethods
      # Provides an ActiveRecord model with Categorizable capabilities
      # Multiple categories can be assigned to instances, through Categorization
      #
      def acts_as_categorizable
        ActiveRecord::Categorizable.register_class(self)

        has_many :categorizations, :as => :categorizable,
                                   :dependent => :destroy
        has_many :categories, :through => :categorizations

        include ActiveRecord::Categorizable::InstanceMethods
      end
    end

    module InstanceMethods
      # Set Categories by their id
      def category_ids=(cids)
        cids ||= []
        #FIXME: optimize
        categorizations.map(&:destroy)
        for cid in cids
          categories << Category.find(cid)
        end
      end
    end
  end
end
