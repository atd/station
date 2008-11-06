module CMS 
  module ActiveRecord
    module Stage
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
      end


      # Instance methods can be redefined in each Model for custom features
      module InstanceMethods
        # Agent must have at least one Performance for this Permission
        def authorizes?(agent, permission)
          has_role_for?(agent, permission)
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
        # permission:: Array with Permission <tt>action</tt> and <tt>objective</tt>
        #
        #   space.roles_for(user, :name => 'Admin') # => true or false
        #   space.roles_for(user, :permission => [ :create, :Attachment ])
        #
        def roles_for(agent, options = {})
          agent_roles = stage_performances.find_all_by_agent_id_and_agent_type(agent.id, agent.class.to_s).map(&:role).uniq

          if options[:name]
            agent_roles = agent_roles.select{ |r| r.name == options[:name] }
          end

          if options[:permission]
            permission = options[:permission].is_a?(Permission) ?
              options[:permission] :
              Permission.find_by_array(options[:permission])

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
