# Current site
class Site < ActiveRecord::Base
  acts_as_container
  has_logo

  def self.current
    first || new
  end
end
