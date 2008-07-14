module CMS
  # Current site
  class Site < ActiveRecord::Base
    acts_as_container
  end
end
