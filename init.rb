config.gem "mislav-will_paginate", :lib => 'will_paginate', 
                                   :version => '>= 2.3.2',
                                   :source => 'http://gems.github.com/'
# Core Extensions
require 'station/core_ext'

# ActiveRecord
require 'active_record/authorization'
ActiveRecord::Base.send :include, ActiveRecord::Authorization

require 'active_record/acts_as'
ActiveRecord::Base.extend ActiveRecord::ActsAs

# Singular Agents
if SingularAgent.table_exists?
  SingularAgent
  Anonymous.current
  Anyone.current
  Authenticated.current
end

# Mime Types
# Redefine Mime::ATOM to include "application/atom+xml;type=entry"
Mime::Type.register "application/atom+xml", :atom, [ "application/atom+xml;type=entry" ]
Mime::Type.register "application/atomsvc+xml", :atomsvc
Mime::Type.register "application/atomcat+xml", :atomcat
Mime::Type.register "application/xrds+xml",    :xrds

# ActionController
for mod in [ ActionController::Station, ActionController::Authentication, ActionController::Authorization ]
  ActionController::Base.send(:include, mod) unless ActionController::Base.ancestors.include?(mod)
end

# ActionView
# Helpers
%w( categories logos sortable station tags ).each do |item|
  require "action_view/helpers/#{ item }_helper"
  ActionView::Base.send :include, "ActionView::Helpers::#{ item.camelcase }Helper".constantize
end
# FormHelpers
%w( categories logo tags ).each do |item|
  require "action_view/helpers/form_#{ item }_helper"
  ActionView::Base.send :include, "ActionView::Helpers::Form#{ item.camelcase }Helper".constantize
end

# Inflections
ActiveSupport::Inflector.inflections do |inflect|
  inflect.uncountable 'cas'
  inflect.uncountable 'anonymous'
end

# i18n
locale_files = 
  Dir[ File.join(File.join(directory, 'config', 'locales'), '*.{rb,yml}') ]

if locale_files.present?
  first_app_element = 
    I18n.load_path.select{ |e| e =~ /^#{ RAILS_ROOT }/ }.reject{ |e|
      e =~ /^#{ RAILS_ROOT }\/vendor\/plugins/ }.first

  app_index = I18n.load_path.index(first_app_element) || - 1

  I18n.load_path.insert(app_index, *locale_files)
end

# Preload Models
file_patterns = [ File.dirname(__FILE__), RAILS_ROOT ].map{ |f| f + '/app/models/**/*.rb' }
file_exclusions = ['svn', 'CVS', 'bzr']
file_patterns.reject{ |f| f =~ /#{file_exclusions.join("|")}/ }

preloaded_files = []

file_patterns.each do |file_pattern|
  Dir[file_pattern].each do |filename|
    open filename do |file|
      preloaded_files << filename if file.grep(/acts_as_(#{ ActiveRecord::ActsAs::Features.join('|') })/).any?
    end
  end
end

# Ensure application modified model files are loaded when autoloading plugin models
preloaded_files.select{ |f| f =~ /^#{ directory }/ }.each do |f|
  app_f = f.gsub(directory, RAILS_ROOT)
  preloaded_files |= [ app_f ] if File.exists?(app_f)
end

preloaded_files.each do |f|
  begin
    require_dependency(f)
  rescue Exception => e
    #FIXME: logger ?
    puts "Station autoload: Couldn't load file #{ f }: #{ e }"
  end
end

# ExceptionNotifier Integration
begin
  def ExceptionNotifier.set_from_site(site)
    if site.respond_to?(:exception_notifications) && site.exception_notifications
      self.exception_recipients = Array(site.exception_notifications_email)
      self.sender_address = %("#{ site.name }" <#{ site.email }>)
    end
  end

  if Site.table_exists?
    ExceptionNotifier.set_from_site(Site.current)
  end

  ActionController::Base.send :include, ExceptionNotifiable
rescue NameError => e
  #TODO: print message when Site.current.exception_notifications is true but
  # exception_notification plugin is missing
end
