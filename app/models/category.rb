class Category < ActiveRecord::Base
  acts_as_sortable :columns => [ :name,
                                 :description,
                                 { :name => "Container", 
                                   :content => proc { |helper, category| 
    container_path = category.container.to_ppath.is_a?(Symbol) ?
      helper.send("#{ category.container.to_ppath }_path") :
      helper.polymorphic_path(category.container.to_ppath)
    helper.link_to(category.container.name, container_path) },
                                   :no_sort => true } ]

  belongs_to :container, 
             :polymorphic => true

  has_many :categorizations,
           :dependent => :destroy
  has_many :posts,
           :through => :categorizations

  validates_presence_of :name, :container_id, :container_type
  validates_uniqueness_of :name, :scope => [ :container_id, :container_type ]
end
