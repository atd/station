module CMS
  # 
  class Categorization < ActiveRecord::Base
    set_table_name "cms_categorizations"

    belongs_to :category,
               :class_name => "CMS::Category"

    belongs_to :post,
               :class_name => "CMS::Post"

    validates_presence_of :category_id, :post_id
  end
end
