require File.dirname(__FILE__) + '/rails_commands'
class CmsGenerator < Rails::Generator::Base
  default_options :skip_migration => false

  def manifest
    record do |m|
      #TODO: check for collisions
      
      m.directory 'app/controllers'
      m.template  'controllers/posts_controller.rb', 'app/controllers/posts_controller.rb'

      m.directory 'app/views/posts'
      m.template 'views/posts/index.html.erb',  'app/views/posts/index.html.erb'
      m.template 'views/posts/show.html.erb',   'app/views/posts/show.html.erb'
      m.template 'views/posts/new.html.erb',    'app/views/posts/new.html.erb'
      m.template 'views/posts/edit.html.erb',   'app/views/posts/edit.html.erb'
      m.template 'views/posts/_form.erb',       'app/views/posts/_form.erb'
      m.template 'views/posts/_file_form.erb',  'app/views/posts/_file_form.erb'
      m.template 'views/posts/_permissions_form.erb', 'app/views/posts/_permissions_form.erb'
      m.template 'views/posts/index.atom.builder', 'app/views/posts/index.atom.builder'
      m.template 'views/posts/_entry.builder',  'app/views/posts/_entry.builder'
      
      m.directory 'app/views/layouts'
      m.template  'views/layout.html.erb', 'app/views/layouts/posts.html.erb'

      unless options[:skip_migration]
        m.migration_template 'migration.rb', 'db/migrate',
          :migration_file_name => "cms_setup"
      end

      m.route_cms
    end
  end

  def add_options!(opt)
    opt.separator ''
    opt.separator 'Options:'
    opt.on("--skip-migration",
           "Don't generate a migration file for CMS database structure") { |v| options[:skip_migration] = v }
  end
end
