require File.dirname(__FILE__) + '/rails_commands'
class CmsGenerator < Rails::Generator::Base
  default_options :skip_migration => false

  def manifest
    record do |m|
      #TODO: check for collisions
      
      m.directory 'public/javascripts/cms'
      m.directory 'public/stylesheets/cms'
      m.directory 'public/images/cms'
      
      unless options[:skip_migration]
        m.migration_template 'migration.rb', 'db/migrate',
          :migration_file_name => "cms_setup"
      end
    end
  end

  def add_options!(opt)
    opt.separator ''
    opt.separator 'Options:'
    opt.on("--skip-migration",
           "Don't generate a migration file for CMS database structure") { |v| options[:skip_migration] = v }
  end
end
