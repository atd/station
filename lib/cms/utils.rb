module CMS
  module Utils
    def self.merge_conditions(operator, *conditions)
      query = conditions.compact.map(&:shift).compact.map{ |c| " (#{ c }) "}.join(operator)
      Array(query) + conditions.flatten.compact
    end
  end
end
