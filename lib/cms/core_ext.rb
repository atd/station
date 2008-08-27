unless Symbol.instance_methods.include? 'to_class'
  Symbol.class_eval do
    def to_class
      self.to_s.classify.constantize
    rescue NameError
      "CMS::#{ self.to_s.classify }".constantize
    end
  end
end

# See Site#to_ppath
unless NilClass.instance_methods.include? 'to_ppath'
  NilClass.class_eval do
    def to_ppath
      nil
    end
  end
end

class ActionController::Resources::Resource
  attr_reader :module_namespace

  def initialize(entities, options)
    module_namespaces = entities.to_s.split('/')

    @plural    ||= module_namespaces.pop
    @singular  ||= options[:singular] || plural.singularize
    @module_namespace ||= module_namespaces.join('/')
    @path_segment = options.delete(:as) || @plural

    @options = options
    options_with_module_namespace

    arrange_actions
    add_default_actions
    set_prefixes
  end

#  def nesting_path_prefix
#    @nesting_path_prefix ||= namespace.empty? ? 
#                             "#{path}/:#{singular}_id" :
#                             "#{path}/:\"#{namespace}/#{singular}_id\"" 
#  end

  protected

  def options_with_module_namespace
    return if module_namespace.empty?

    options[:controller] ||= "#{ module_namespace }/#{ plural }"
    options[:path_prefix] = "#{ options[:path_prefix] }/#{ module_namespace }"
    options[:name_prefix] = "#{ options[:name_prefix] }#{ module_namespace.gsub('/', '_') }_"
  end
end

class ActionController::Resources::SingletonResource
  attr_reader :namespace

  def initialize(entity, options)
    module_namespaces = entity.to_s.split('/')

    @singular  = @plural = module_namespaces.pop
    @module_namespace = module_namespaces.join('/')
    options[:controller] ||= "#{ module_namespace }/#{ singular.pluralize }"
    super
  end
end


