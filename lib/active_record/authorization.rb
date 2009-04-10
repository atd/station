module ActiveRecord #:nodoc:
  # Authorization module provide ActiveRecord models with authorization features.
  #
  #
  # Include Authorization functionality in your models using ActsAsMethods#
  module Authorization
    class << self
      def included(base) #:nodoc:
        base.extend ClassMethods
        base.send :include, InstanceMethods
      end
    end

    module ClassMethods
      def reflection_affordances_list
        @reflection_affordances_list ||= {}
      end

      def reflection_affordances(reflection, options = {})
        reflection_affordances_list[reflection] = options
      end
    end

    # Instance methods can be redefined in each Model for custom features
    module InstanceMethods
      # There is authorization if there are any affordances that match the action
      #
      # action can be:
      # ActiveRecord::Authorization::Agent instance
      # Symbol or String:: describes the action name. Objective will be nil
      #   resource.authorizes?(:update, :to => user)
      # Array:: pair of action_name, :objective
      #   resource.authorizes?([ :create, :attachment ], :to => user)
      #
      # Options:
      # to:: Agent of the Affordance. Defaults to Anyone
      #
      def authorizes?(action, options = {})
        options[:action] = action
        options[:agent] = options.delete(:to) || Anyone.current

        affordance?(options)
      end

      def affordances
        @affordances ||= local_affordances | import_affordances
      end

      def affordance?(options = {})
        candidates = []

        if options[:agent]
          candidates |= affordances.select{ |a| a.agent == options[:agent] }
        end

        candidates |= affordances.select{ |a| a.anyone? }

        if options[:action]
          candidates.delete_if{ |a| !a.action?(options[:action]) }
        end

        candidates.any?
      end

      # Options:
      # agent:: 
      def import_affordances
        self.class.reflection_affordances_list.inject([]) do |affordances, r|
          reflection, reflection_options = r.first, r.last

          affs = send("#{ reflection }_affordances")

          if reflection_options[:objective]
            affs = affs.select{ |a| 
              a.action.objective?(reflection_options[:objective]) 
            }.map{ |a|
             a.action.objective = nil
             a
            }
          end

          affordances | affs
        end
      end

      def local_affordances
        affordances_from_hash
      end

      def affordances_hash
        {}
      end

      def affordances_from_hash
        affordances_hash.inject([]) do |affordances, e|
          agent, actions = e.first, e.last

          affordances | actions.map{ |action| Affordance.new(agent, action) }
        end
      end
    end

    class Action
      attr_reader :name
      attr_accessor :objective

      def initialize(name, objective = nil)
        @name, @objective = name.to_s, objective
      end

      def ==(a)
        self.name == a.name && objective?(a.objective)
      end

      def objective?(o)
        objective.to_s == o.to_s
      end

      def inspect
        "#<Action:#{ object_id } @name:#{ @name.inspect } @objective:#{ @objective.inspect }>"
      end
    end

    class Affordance
      attr_reader :agent, :action

      def initialize(agent, action)
        raise "Invalid Affordance: agent: #{ agent }, action: #{ action }" unless 
        agent && action
        @agent, @action = agent, (action.is_a?(Action) ? action : Action.new(*action))
      end

      # Two affordances are equivalent when their agents and actions are the same
      def ==(a)
        self.agent == a.agent && self.action == a.action
      end

      # Is this action equal to the Affordance action?
      def action?(action)
        @action == Action.new(*action)
      end

      # Is agent equal to the Affordance agent?
      def agent?(agent)
        @agent == agent
      end

      # Is agent Anyone?
      def anyone?
        agent?(Anyone.current)
      end

      def inspect
        "#<Affordance:#{ object_id } @agent: #{ agent }, @action: #{ action.inspect }>"
      end
    end
  end
end
