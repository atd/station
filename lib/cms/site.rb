module CMS
  # Current site
  class Site < ActiveRecord::Base
    set_table_name "cms_sites"
    
    acts_as_container
  end
end
