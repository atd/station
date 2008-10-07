# Current site
class Site < ActiveRecord::Base
  acts_as_container

  def self.current
    first || new
  end
end
