# Singular Agents: Anonymous, Anyone, Authenticated, etc..
class SingularAgent < ActiveRecord::Base
  acts_as_agent :authentication => [],
                :invite         => false

  class << self
    def current
      @current ||= first || create
    end
  end

  def name
    I18n.t :name, :scope => "singular_agent.#{ self.class.to_s.underscore }"
  end

  alias login name
end

# Not authenticated Agent
class Anonymous < SingularAgent ; end
# All Agents, including Anonymous
class Anyone < SingularAgent ; end
# Every Agent authenticated
class Authenticated < SingularAgent ; end
