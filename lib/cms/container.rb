module CMS 
  # Container(s) are models receiving Content(s) posted by Agent(s)
  module Container
    def self.included(base) #:nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      # Provides an ActiveRecord model with Container capabilities
      #
      # Content(s) are posted by Agent(s) to Container(s), giving Post(s)
      #
      # Options:
      # * <tt>contents</tt>: an Array of Content that can be posted to this Container. Ex: [ :articles, :images ]. Defaults to all available Content(s)
      # * <tt>name</tt>: alias attribute for Content presentation
      #
      def acts_as_container(options = {})
        CMS.register_model(self, :container)
        def self.inherited(subclass)
          super
          CMS.register_model(subclass, :container)
        end

        send(:alias_attribute, :name, options.delete(:name)) if options[:name]

        cattr_reader :container_options
        class_variable_set "@@container_options", options

        has_many :container_posts, 
                 :class_name => "Post",
                 :dependent => :destroy,
                 :as => :container


        has_many :container_performances,
                 :class_name => "Performance",
                 :dependent => :destroy,
                 :as => :container

        has_many :container_categories,
                 :class_name => "Category",
                 :dependent => :destroy,
                 :as => :container

        include CMS::Container::InstanceMethods
      end
    end


    # Instance methods can be redefined in each Model for custom features
    module InstanceMethods
      def accepted_content_types
        self.class.container_options[:content_types] || CMS.contents
      end

      # Agent must have at least one performance for every action
      def authorizes?(agent, actions)
        for action in Array(actions)
          return false unless self.has_role_for?(agent, action)
        end
        true
      end
      
      # All roles performed by some Agent in this Container.
      #
      # If action is specified, return all roles allowing the Agent to perform the action in this Container
      def roles_for(agent, action = nil)
        return Array.new unless agent.respond_to?(:agent_options)

        agent_roles = container_performances.find_all_by_agent_id_and_agent_type(agent.id, agent.class.to_s).map(&:role).uniq

        return agent_roles unless action

        action = action.to_sym
        agent_roles.select(&action)
      rescue NoMethodError => e
        raise Exception.new("At least one role doesn't support \"#{ action }\" method")
      end
      
      # True if it exists at least one Performance for this Container.
      #
      # If some action is specified, return true if there is at least one role that allows
      # the Agent to perform the action.
      #
      #   space.has_role_for?(user, :admin) # => true or false
      #
      def has_role_for?(agent, action = nil)
        roles_for(agent, action).any?
      end
      
      # Return all agents that play one role at least in this container
      # 
      # TODO: conditions (roles, etc...)
      def actors
        container_performances.map(&:agent).uniq
      end
    end
  end
end
