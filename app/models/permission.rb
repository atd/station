class Permission < ActiveRecord::Base
  has_and_belongs_to_many :roles

  validates_presence_of :action, :objective

  def title
    I18n.t(action, :scope => objective.underscore)
  end
end
