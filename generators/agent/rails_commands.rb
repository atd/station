Rails::Generator::Commands::Create.class_eval do
  def route_resource(*resources)
    resource_list = resources.map { |r| r.to_sym.inspect }.join(', ')
    sentinel = 'ActionController::Routing::Routes.draw do |map|'

    logger.route "map.resource #{resource_list}"
    unless options[:pretend]
      gsub_file 'config/routes.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
        "#{match}\n  map.resource #{resource_list}\n"
      end
    end
  end

  def route_named(name, route, route_options = {})
    named_route = "map.#{ name } '#{ route }', #{ route_options.inspect }"
    logger.route named_route

    sentinel = 'ActionController::Routing::Routes.draw do |map|'
    unless options[:pretend]
      gsub_file 'config/routes.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
        "#{ match }\n  #{ named_route } \n"
      end
    end
  end
end

Rails::Generator::Commands::Destroy.class_eval do
  def route_resource(*resources)
    resource_list = resources.map { |r| r.to_sym.inspect }.join(', ')
    look_for = "\n  map.resource #{resource_list}\n"
    logger.route "map.resource #{resource_list}"
    unless options[:pretend]
      gsub_file 'config/routes.rb', /(#{look_for})/mi, ''
    end
  end

  def route_named(name, route, route_options = {})
    named_route = "map.#{ name } '#{ route }', #{ route_options.inspect }"
    logger.route named_route

    look_for = "\n  #{ named_route } \n"
    unless options[:pretend]
      gsub_file 'config/routes.rb', /(#{ Regexp.escape(look_for) })/mi, ''
    end
  end
end

Rails::Generator::Commands::List.class_eval do
  def route_resource(*resources)
    resource_list = resources.map { |r| r.to_sym.inspect }.join(', ')
    logger.route "map.resource #{resource_list}"
  end

  def route_named(name, route, route_options = {})
    logger.route "map.#{ name } '#{ route }', #{ route_options.inspect }"
  end
end
