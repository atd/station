module CMS
  # 
  class Category < ActiveRecord::Base
    set_table_name "cms_categories"

    belongs_to :container, 
               :polymorphic => true

    has_many :categorizations,
             :class_name => "CMS::Categorization",
             :dependent => :destroy
    has_many :posts,
             :through => :categorizations

    validates_presence_of :name, :container_id, :container_type
    validates_uniqueness_of :name, :scope => [ :container_id, :container_type ]
  end
end
