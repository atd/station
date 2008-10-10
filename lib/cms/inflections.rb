module CMS
  class << self
    # Add plugin inflections
    def inflections
      ActiveSupport::Inflector.inflections do |inflect|
        inflect.uncountable 'cas'
      end
    end
  end
end
