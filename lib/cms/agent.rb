module CMS
  # Agent(s) can CRUD Content(s) in Container(s), generating Post(s)
  module Agent
    def self.include(base) #:nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      def acts_as_agent(options = {})
        include CMS::Agent::InstanceMethods
      end
    end

    module InstanceMethods
    end
  end
end
