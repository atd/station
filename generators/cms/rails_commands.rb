Rails::Generator::Commands::Create.class_eval do
  def route_cms
    sentinel = 'ActionController::Routing::Routes.draw do |map|'

    logger.route "CMS"
    unless options[:pretend]
      gsub_file 'config/routes.rb', /(#{Regexp.escape(sentinel)})/mi do |match|
        "#{ match }\n  map.from_plugin 'cmsplugin'\n"
      end
    end
  end
end

Rails::Generator::Commands::Destroy.class_eval do
  def route_cms
    look_for = "\n  map.from_plugin 'cmsplugin'\n"

    logger.route "CMS"
    unless options[:pretend]
      gsub_file 'config/routes.rb', /(#{Regexp.escape(look_for)})/mi, ''
    end
 end
end

Rails::Generator::Commands::List.class_eval do
  def route_cms
    logger.route "CMS"
  end
end
