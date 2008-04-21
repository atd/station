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
        options[:contents] ||= CMS.contents

        send(:alias_attribute, :name, options.delete(:name)) if options[:name]

        cattr_reader :container_options
        class_variable_set "@@container_options", options

        has_many :posts, :as => :container,
                         :class_name => "CMS::Post"

        has_many :performances,
                 :class_name => "CMS::Performance",
                 :dependent => :destroy,
                 :as => :container

        include CMS::Container::InstanceMethods
        
        # This methods maps the appropriate attributes
        send :alias_method_chain, :method_missing, :roled_actions
      end
    end


    # Instance methods can be redefined in each Model for custom features
    module InstanceMethods
      # Catch all methods like "read_by?(agent)"
      # If there is any performance for that agent that respond true to action
      def method_missing_with_roled_actions(method, *args, &block) #:nodoc:
        if method.to_s =~ /^(.*)_by\?$/
          action = "#{ $1 }?".to_sym
          agent = args.first
          agent_roles = performances.find_all_by_agent_id_and_agent_type(agent.id, agent.class.to_s).map(&:role)
          agent_roles.select(&action).any?
          # TODO rescue NoMethodError when a Role doesn't support "action" and raise useful message
        else
          method_missing_without_roled_actions(method, *args, &block)
        end
      end
      
      # Return all agents that play one role at least in this container
      # 
      # TODO: conditions (roles, etc...)
      def agents
        performances.map(&:agent).uniq
      end
      
      # Does this agent manage the container?
      def has_owner?(agent)
        self == agent
      end
    end
  end
end
