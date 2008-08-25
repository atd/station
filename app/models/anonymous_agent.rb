# Anonymous Agent Class
class AnonymousAgent < ActiveRecord::Base
  acts_as_agent :authentication => []

  # Anonymous Agent
  def self.current
    self.first || self.create
  end

  def name
    "Anonymous".t
  end
end
