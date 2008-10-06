# Performance define the Role some Actor is playing in some Container
#
# == Named scopes
#
# container_type(type): find Peformances by container type
class Performance < ActiveRecord::Base
  belongs_to :agent,     :polymorphic => true
  belongs_to :container, :polymorphic => true
  belongs_to :role

  named_scope :container_type, lambda { |type|
    type ?
      { :conditions => [ "container_type = ?", type.to_s.classify ] } :
      {}
  }
end
