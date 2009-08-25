module ActiveRecord #:nodoc:
  module Authorization #:nodoc:
    class ACEPermission
      attr_reader :action, :objective

      def initialize(action, objective = nil)
        @action, @objective = ACEAction.new(action), ACEObjective.new(objective)
      end

      def ==(p)
        self.action == p.action && self.objective == p.objective
      end

      def action?(a)
        self.action == ACEAction.new(a)
      end

      def objective?(o)
        self.objective == ACEObjective.new(o)
      end

      def inspect
        "#<ACEPermission: @action:#{ @action.inspect } @objective:#{ @objective.inspect }>"
      end
    end
  end
end
