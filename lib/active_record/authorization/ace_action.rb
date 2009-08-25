module ActiveRecord #:nodoc:
  module Authorization #:nodoc:
    class ACEAction < String
      def initialize(value)
        raise "Invalid ACE, Action missing" unless value.present?

        super(value.to_s)
      end
    end
  end
end
