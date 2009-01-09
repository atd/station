# Singular Agents: Anonymous, Anyone, etc..
class SingularAgent < ActiveRecord::Base
  acts_as_agent :authentication => []

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

class Anonymous < SingularAgent ; end
class Anyone < SingularAgent ; end

