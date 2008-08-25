# Agents play Roles in Containers
#
# Roles control permissions
class Role < ActiveRecord::Base
  has_many :performances

  validates_presence_of :name
  validates_uniqueness_of :name
end
