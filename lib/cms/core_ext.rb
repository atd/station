unless Symbol.instance_methods.include? 'to_class'
  Symbol.class_eval do
    def to_class
      self.to_s.classify.constantize
    end
  end
end
