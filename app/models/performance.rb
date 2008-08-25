# Performance define the Role some Actor is playing in some Container
class Performance < ActiveRecord::Base
  belongs_to :agent,     :polymorphic => true
  belongs_to :container, :polymorphic => true
  belongs_to :role
end
