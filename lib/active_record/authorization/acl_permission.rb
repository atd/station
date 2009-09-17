module ActiveRecord #:nodoc:
  module Authorization #:nodoc:
    class ACLPermission
      attr_reader :action, :objective

      def initialize(action, objective = nil)
        @action, @objective = ACLAction.new(action), ACLObjective.new(objective)
      end

      def ==(p)
        self.action == p.action && self.objective == p.objective
      end

      def action?(a)
        self.action == ACLAction.new(a)
      end

      def objective?(o)
        self.objective == ACLObjective.new(o)
      end

      def inspect
        "#<ACLPermission: @action:#{ @action.inspect } @objective:#{ @objective.inspect }>"
      end
    end
  end
end
