module CMS
  # Performance define the Role some Actor is playing in some Container
  class Performance < ActiveRecord::Base
    set_table_name "cms_performances"
    
    belongs_to :agent,     :polymorphic => true
    belongs_to :container, :polymorphic => true
    belongs_to :role, :class_name => "CMS::Role"    
  end
end