class Categorization < ActiveRecord::Base
  belongs_to :category
  belongs_to :entry

  validates_presence_of :category_id, :entry_id
end
