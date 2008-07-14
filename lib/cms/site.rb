module CMS
  # Current site
  class Site < ActiveRecord::Base
    set_table_name "cms_sites"
    
    acts_as_container

    def self.current
      first || new
    end
  end
end
