module CMS 
  module ActiveRecord
    module Stage
      include ActsAs

      class << self
        def included(base) #:nodoc:
          base.extend ClassMethods
        end
      end

      module ClassMethods
        # Provides an ActiveRecord model with Authorization capabilities
        #
        # Stages have Performance
        #
        def acts_as_stage(options = {})
          CMS::ActiveRecord::Stage.register_class(self)

          cattr_reader :stage_options
          class_variable_set "@@stage_options", options

          has_many :stage_performances,
                   :class_name => "Performance",
                   :dependent => :destroy,
                   :as => :stage

          include CMS::ActiveRecord::Stage::InstanceMethods
        end

        # All Roles defined for this class
        def roles
          Role.find_all_by_stage_type self.to_s
        end
      end

      # Instance methods can be redefined in each Model for custom features
      module InstanceMethods
        # agent is authorized in the Stage if it has at least one Role that 
        # has one Permission for performing action_objective
        #
        # If the Stage is also a Content, it has entries, authorizes? looks for authorization
        # in those entries' containers.
        #
        # action_objective can be:
        # Symbol or String:: describes the action of the Permission. Objective will be :self
        #   stage.authorizes?(agent, :update)
        # Array:: pair of :action, :objective
        #   stage.authorizes?(agent, [ :create, :Attachment ])
        #
        def authorizes?(agent, action_objective)
          if respond_to?(:content_entries) && 
             (action_objective.is_a?(Symbol) || action_objective.is_a?(String))
            content_entries.map(&:container).map{ |c| 
              if c.authorizes?(agent, [ action_objective, :Content ]) || 
                 c.authorizes?(agent, [ action_objective, self.class.to_s ]) 
                return true
              end
            }
          end

          action_objective = Array(action_objective)
          action_objective << :self unless action_objective.size > 1

          has_role_for?(agent, :permission => action_objective)
        end

        # True if it exists at least one Performance for the Agent in this Stage.
        #
        # Options: See roles_for options
        #
        def has_role_for?(agent, options = {})
          roles_for(agent, options).any?
        end
       
        # All roles performed by some Agent in this Stage.
        #
        # Options:
        # name:: Name of the Roles
        #   space.roles_for(user, :name => 'Admin')
        # permission:: Array with Permission <tt>action</tt> and <tt>objective</tt>
        #   space.roles_for(user, :permission => [ :create, :Attachment ])
        #
        def roles_for(agent, options = {})
          agent_roles = stage_performances.find_all_by_agent_id_and_agent_type(agent.id, agent.class.to_s).map(&:role).uniq

          if agent_roles.include?(nil)
            puts '+++++++++++++++++++++++'
            puts self.inspect
            puts stage_performances.find_all_by_agent_id_and_agent_type(agent.id, agent.class.to_s).inspect
          end

          if options[:name]
            agent_roles = agent_roles.select{ |r| r.name == options[:name] }
          end

          if options[:permission]
            permission = options[:permission].is_a?(Permission) ?
              options[:permission] :
              Permission.find_by_action_and_objective(*options[:permission].map(&:to_s))

            agent_roles = agent_roles.select{ |r| r.permissions.include?(permission) }
          end

          agent_roles
        end
        
        # Return all agents that play one role at least in this stage
        # 
        # TODO: conditions (roles, etc...)
        def actors
          stage_performances.map(&:agent).uniq
        end
      end
    end
  end
end
