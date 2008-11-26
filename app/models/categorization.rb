class Categorization < ActiveRecord::Base
  belongs_to :category
  belongs_to :categorizable, :polymorphic => true

  validates_presence_of :category_id, :categorizable_id, :categorizable_type
end
