# Agents play Roles in Containers
#
# Roles control permissions
class Role < ActiveRecord::Base
  has_many :performances

  acts_as_sortable :columns => [ :name,
                                 :create_entries,
                                 :read_entries,
                                 :update_entries,
                                 :delete_entries,
                                 :create_performances,
                                 :read_performances,
                                 :update_performances,
                                 :delete_performances ]

  validates_presence_of :name
  validates_uniqueness_of :name
end
