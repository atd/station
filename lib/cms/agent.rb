require 'digest/sha1'

module CMS
  # Agent(s) can CRUD Content(s) in Container(s), generating Post(s)
  module Agent

    def self.included(base) #:nodoc:
      base.extend ClassMethods
    end

    # Returns the first model that acts as Agent, has activation enabled and 
    # login and password
    def self.activation_class
      CMS.agents.map(&:to_class).select{ |a| a.agent_options[:activation] && a.agent_options[:authentication].include?(:login_and_password) }.first
    end

    module ClassMethods
      # Provides an ActiveRecord model with Agent capabilities
      #
      # Agent(s) can post Content(s) to Container(s)
      #
      # Options
      # * <tt>authentication</tt>: Array with Authentication methods supported for this Agent. 
      # Defaults to <tt>[ :login_and_password, :openid ]</tt>
      # * <tt>activation</tt>: Agent must verify email
      def acts_as_agent(options = {})
        CMS.register_model(self, :agent)

        options[:authentication] ||= [ :login_and_password, :openid ]
        
        cattr_reader :agent_options
        class_variable_set "@@agent_options", options

        #
        # Authentication Methods
        #

        if options[:authentication].include? :login_and_password
          include CMS::Agent::Authentication::LoginAndPassword
        end

        if options[:authentication].include? :openid
          include CMS::Agent::Authentication::OpenID
        end

        # Verifies agent email
        if options[:activation]
          include CMS::Agent::Activation
        end

        # Remember Agent in browser through cookies
        include CMS::Agent::Remember

        has_many :agent_posts,
                 :class_name => "Post",
                 :dependent => :destroy,
                 :as => :agent

        has_many :agent_performances, 
                 :class_name => "Performance", 
                 :dependent => :destroy,
                 :as => :agent

        include CMS::Agent::InstanceMethods
      end
    end

    module InstanceMethods
      # All Containers in which this Agent has a Performance
      #
      # Can pass options to the list:
      # type:: the class of the Containers requested
      def stages(options = {})
        returning agent_performances.map(&:container).uniq do |stages|
          if options[:type]
            type = options[:type].to_s.classify.constantize
            stages = stages.select{ |s| s.is_a?(type) }
          end
        end
      end

      def service_documents
        if self.agent_options[:authentication].include?(:openid)
          openid_uris.map(&:atompub_service_document)
        else
          Array.new
        end
      end
    end
  end
end
