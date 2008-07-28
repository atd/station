module CMS
  # 
  class Category < ActiveRecord::Base
    set_table_name "cms_categories"

    acts_as_sortable :columns => [ { :name => "Name", :content => :name },
                                   { :name => "Description", :content => :description },
                                   { :name => "Container", :content => proc { |helper, category| helper.link_to(category.container.name, helper.polymorphic_path(category.container)) }, :no_sort => true } ]

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
