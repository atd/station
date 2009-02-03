class Category < ActiveRecord::Base
  acts_as_sortable :columns => [ :name,
                                 :description,
                                 { :name => I18n.t('category.domain.one'), 
                                   :content => :domain,
                                   :sortable => false } ]

  belongs_to :domain, 
             :polymorphic => true

  has_many :categorizations,
           :dependent => :destroy

  ActiveRecord::Categorizable.symbols.each do |categorizable|
    has_many categorizable, :through => :categorizations,
                            :source => :categorizable,
                            :source_type => categorizable.to_s.classify
  end

  # All the instances categorized with some Category
  def categorizables
    ActiveRecord::Categorizable.symbols.map{ |t| send(t) }.flatten
  end

  validates_presence_of :name, :domain_id, :domain_type
  validates_uniqueness_of :name, :scope => [ :domain_id, :domain_type ]
end
