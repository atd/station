module ActiveRecord #:nodoc:
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
        ActiveRecord::Stage.register_class(self)

        cattr_reader :stage_options
        class_variable_set "@@stage_options", options

        has_many :stage_performances,
                 :class_name => "Performance",
                 :dependent => :destroy,
                 :as => :stage

        has_many :stage_invitations,
                 :class_name => "Invitation",
                 :dependent => :destroy,
                 :as => :stage

        include ActiveRecord::Stage::InstanceMethods

        send :attr_accessor, :_stage_performances
        after_save :_save_stage_performances!
      end

      # All Roles defined for this class
      def roles
        Role.find_all_by_stage_type self.to_s
      end
    end

    # Instance methods can be redefined in each Model for custom features
    module InstanceMethods
      # agent is authorized in the Stage if its Role has a Permission
      # matching action_objective
      #
      # If the Stage is also a Content, it has entries, authorizes? looks for authorization
      # in those entries' Containers.
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

        permission = action_objective.is_a?(Permission) ?
          action_objective :
          Permission.find_by_action_and_objective(*action_objective.map(&:to_s))

        role_for(agent) && role_for(agent).permissions.include?(permission) ||
          role_for(Anyone.current) && role_for(Anyone.current).permissions.include?(permission)
      end

      # True if agent has a Performance in this Stage.
      #
      # Options:
      # name:: Name of the Role
      #   space.role_for?(user, :name => 'Admin')
      def role_for?(agent, options = {})
        return false unless role_for(agent)

        options[:name] ?
          role_for(agent).name == options[:name] :
          true
      end
     
      # Role performed by this Agent in the Stage.
      #
      def role_for(agent)
        #FIXME: Role named scope
        Role.find :first,
                  :joins => :performances,
                  :conditions => { 'performances.agent_id'   => agent.id,
                                   'performances.agent_type' => agent.class.base_class.to_s,
                                   'performances.stage_id'   => self.id,
                                   'performances.stage_type' => self.class.base_class.to_s },
                  :include => :permissions
      end
      
      # Return all agents that play one role at least in this stage
      # 
      # TODO: conditions (roles, etc...)
      def actors
        stage_performances.map(&:agent)
      end

      private

      def _save_stage_performances! #:nodoc:
        return unless @_stage_performances

        Performance.transaction do
          old_ps = stage_performances.clone

          @_stage_performances.each do |new_p|
            present_p = stage_performances.find :first, :conditions => new_p

            present_p ?
              old_ps.delete(present_p) :
              stage_performances.create!(new_p)
          end

          old_ps.map(&:destroy)
        end

        @_stage_performances = nil
      end
    end
  end
end
