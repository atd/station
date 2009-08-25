module ActiveRecord #:nodoc:
  module Authorization #:nodoc:
    # Access Control Entry (ACE)
    class ACE
      attr_reader :agent, :permission

      def initialize(agent, *args)
        @agent, @permission = agent, ACEPermission(*args)
      end

      # Two ACEs are equivalent when their agents and permissions are the same
      def ==(ace)
        agent?(ace.agent) && permission?(ace.permission)
      end

      # Is this ACE agent equal to agent?
      def agent?(agent)
        self.agent == agent
      end

      # Is this ACE permission equivalent to args?
      def permission?(*args)
        self.permission == ACEPermission(*args)
      end

      # Returns the action of this ACE permission
      def action
        self.permission.action
      end

      # Is the action of this ACE permission equal to action?
      def action?(action)
        self.permission.action?(action)
      end

      # Returns the objective of this ACE permission
      def objective
        self.permission.objective
      end

      # Is the objective of this ACE permission equal to objective?
      def objective?(objective)
        self.permission.objective?(objective)
      end

      # Is this ACE agent equal to Anyone?
      def anyone?
        agent?(Anyone.current)
      end

      def inspect
        "#<ACE: #{ agent.respond_to?(:name) && "\"#{ agent.name }\"" || agent } #{ action } #{ objective }>"
      end

      def ACEPermission(*args)
        args.first.is_a?(ACEPermission) ?
          args.first :
          ACEPermission.new(*args)
      end
    end
  end
end
