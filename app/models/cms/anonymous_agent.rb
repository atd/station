module CMS
  # Anonymous Agent Class
  class AnonymousAgent < ActiveRecord::Base
    set_table_name "cms_anonymous_agents"

    acts_as_agent :authentication => []

    # Anonymous Agent
    def self.current
      self.first || self.create
    end

    def name
      "Anonymous".t
    end
  end
end
