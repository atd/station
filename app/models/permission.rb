class Permission < ActiveRecord::Base
  has_and_belongs_to_many :roles

  validates_presence_of :action

  def title
    objective ?
      I18n.t(action, :scope => objective.underscore, :count => :other) :
      I18n.t(action)
  end

  def <=>(other)
    title <=> other.title
  end

  # Return the equivalent ACEPermission for this database Permission
  def to_ace_permission
    ActiveRecord::Authorization::ACEPermission.new action, objective
  end

end
