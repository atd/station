module ActiveRecord #:nodoc:
  module Authorization #:nodoc:
    class ACLAction < String
      def initialize(value)
        raise "Invalid ACL, Action missing" unless value.present?

        super(value.to_s)
      end
    end
  end
end
