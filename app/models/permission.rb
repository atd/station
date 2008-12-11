class Permission < ActiveRecord::Base
  has_and_belongs_to_many :roles

  validates_presence_of :action, :objective

  def title
    "#{ action.humanize.t } #{ objective.humanize.t }"
  end
end
