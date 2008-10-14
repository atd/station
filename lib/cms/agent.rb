require 'digest/sha1'

module CMS
  # Agent(s) can CRUD Content(s) in Container(s), generating Entry(s)
  module Agent
    class << self
      # Agent Classes
      def classes
        CMS.agents.map(&:to_class)
      end

      # Returns the first model that acts as Agent, has activation enabled and 
      # login and password
      def activation_class
        classes.select{ |a| a.agent_options[:activation] && 
          a.agent_options[:authentication].include?(:login_and_password) }.first
      end

      # An Array with Agent classes supporting authentication @method@
      def authentication_classes(method = nil)
        classes.select{ |klass|
          klass.agent_options[:authentication] 
        }.select { |klass|
          method ?
            klass.agent_options[:authentication].include?(method) :
            ! klass.agent_options[:authentication].blank? 
        }
      end

      # An Array with all authentication methods supported by the application
      def authentication_methods
        classes.map{ |a| a.agent_options[:authentication] }.flatten.uniq
      end

      def included(base) #:nodoc:
        base.extend ClassMethods
      end
    end

    module ClassMethods
      # Provides an ActiveRecord model with Agent capabilities
      #
      # Agent(s) can entry Content(s) to Container(s)
      #
      # Options
      # * <tt>authentication</tt>: Array with Authentication methods supported for this Agent. 
      # Defaults to <tt>[ :login_and_password, :openid ]</tt>
      # * <tt>activation</tt>: Agent must verify email
      def acts_as_agent(options = {})
        CMS.register_model(self, :agent)

        options[:authentication] ||= [ :login_and_password, :openid, :cookie_token ]
        
        # Set agent options
        #
        cattr_reader :agent_options
        class_variable_set "@@agent_options", options

        # Load Authentication Methods
        #
        options[:authentication].each do |method|
          include "CMS::Agent::Authentication::#{ method.to_s.camelize }".constantize
        end

        # Loads agent email verification
        if options[:activation]
          include CMS::Agent::Activation
        end

        has_many :agent_entries,
                 :class_name => "Entry",
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
      # type:: the class of the Containers requested (Doesn't work with STI!)
      #
      def stages(options = {})
        agent_performances.container_type(options[:type]).map(&:container).uniq
      end

      def service_documents
        if self.agent_options[:authentication].include?(:open_i_d)
          openid_uris.map(&:atompub_service_document)
        else
          Array.new
        end
      end
    end
  end
end
