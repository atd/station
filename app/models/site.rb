# Current site
class Site < ActiveRecord::Base
  acts_as_container
  acts_as_logotypable

  def self.current
    first || new
  end
end
