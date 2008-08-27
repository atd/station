# Current site
class Site < ActiveRecord::Base
  acts_as_container

  def self.current
    first || new
  end

  # Return symbol for polymorphic_path because Site it is a single resource
  #
  # Example:
  #   # current_container = Site.current
  #   polymorphic_path([ current_container, Category.new ]) #=> site_categories_path
  def to_ppath
    :site
  end
end
