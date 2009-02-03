module ActiveRecord #:nodoc:
  # CategoriesDomain ActiveRecord module
  module CategoriesDomain
    include ActsAs

    class << self
      def included(base) #:nodoc:
        base.extend ClassMethods
      end
    end

    module ClassMethods
      # Provides an ActiveRecord model with CategoriesDomain capabilities
      #
      def acts_as_categories_domain
        ActiveRecord::CategoriesDomain.register_class(self)

        has_many :domain_categories, 
                 :as => :domain,
                 :class_name => "Category",
                 :dependent => :destroy
      end
    end
  end
end
