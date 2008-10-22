class Permission < ActiveRecord::Base
  has_and_belongs_to_many :roles

  validates_presence_of :action, :objective

  class << self
    # Find permission by Array of [ :action, :objective ]
    def find_by_array(ary)
      raise "#{ ary.inspect } is not an Array" unless ary.is_a?(Array)
      raise "Array size must be 2, but it is #{ ary.size }" unless ary.size == 2

      find_by_action_and_objective *(ary.map(&:to_s))
    end
  end

  def title
    "#{ action.humanize.t } #{ objective.humanize.t }"
  end
end
