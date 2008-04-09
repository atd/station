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
        cattr_reader :contents

        options[:contents] ||= CMS.contents

        send(:alias_attribute, :name, options.delete(:name)) if options[:name]

        options.each_pair do |var, value|
          class_variable_set "@@#{ var }", value
        end

        has_many :posts, :as => :container,
                         :class_name => "CMS::Post"

        has_many :performances,
                 :class_name => "CMS::Performance",
                 :dependent => :destroy,
                 :as => :container

        include CMS::Container::InstanceMethods
      end
    end


    # Instance methods can be redefined in each Model for custom features
    module InstanceMethods
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

      # Can agent get posts from this container?
      # Note that each post defines it own permissions, thus overwrites this
      def read_by?(agent)
        true
      end

      # Can <tt>agent</tt> post to this container?
      def write_by?(agent)
        self == agent
      end
    end
  end
end
