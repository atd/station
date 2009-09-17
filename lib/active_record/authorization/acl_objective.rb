module ActiveRecord #:nodoc:
  module Authorization #:nodoc:
    class ACLObjective
      attr_reader :value

      class << self
        def normalize(value)
          case value
          when NilClass
            nil
          when ACLObjective
            value.value
          else
            value.to_s.singularize.underscore
          end
        end
      end

      def initialize(value)
        @value = self.class.normalize(value)
      end

      #TODO: delegate to value

      def ==(objective)
        self.value == objective.value
      end

      def to_s
        value.to_s
      end

      def inspect
        value.inspect
      end
    end
  end
end
