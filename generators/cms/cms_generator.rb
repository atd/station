require File.dirname(__FILE__) + '/rails_commands'
class CmsGenerator < Rails::Generator::Base
  def manifest
    record do |m|
      #TODO: check for collisions

      m.file 'public/403.html', 'public/403.html'

      m.route_cms
    end
  end
end
