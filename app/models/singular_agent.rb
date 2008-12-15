# Singular Agents: Anonymous, Anyone, etc..
class SingularAgent < ActiveRecord::Base
  acts_as_agent :authentication => []

  class << self
    def current
      @current ||= first || create
    end
  end

  def name
    self.class.to_s.t
  end

  def login
    self.class.to_s.underscore.t
  end
end

class Anonymous < SingularAgent ; end
class Anyone < SingularAgent ; end

