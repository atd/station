class Categorization < ActiveRecord::Base
  belongs_to :category
  belongs_to :post

  validates_presence_of :category_id, :post_id
end
