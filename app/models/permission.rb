class Permission < ActiveRecord::Base
  has_and_belongs_to_many :roles

  validates_presence_of :action

  def title
    objective == 'self' ?
      I18n.t(action) :
      I18n.t(action, :scope => objective.underscore, :count => :other)
  end

  def <=>(other)
    title <=> other.title
  end
end
