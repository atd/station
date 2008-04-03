module CMS
  # Agents play Roles in Containers
  #
  # Roles control permissions
  class Role < ActiveRecord::Base
    set_table_name "cms_roles"
   
    has_many :performances, 
             :class_name => "CMS::Performance"
  end
end