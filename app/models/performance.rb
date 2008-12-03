# Performance define the Role some Actor is playing in some Stage
#
# == Named scopes
#
# stage_type(type): find Peformances by Stage type
class Performance < ActiveRecord::Base
  belongs_to :agent,     :polymorphic => true
  belongs_to :stage, :polymorphic => true
  belongs_to :role

  named_scope :stage_type, lambda { |type|
    type ?
      { :conditions => [ "stage_type = ?", type.to_s.classify ] } :
      {}
  }

  validates_presence_of :agent_id, :agent_type, :stage_id, :stage_type, :role_id
end
