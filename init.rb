config.gem "ruby-openid", :lib => 'openid', :version => '>= 2.0.4'
config.gem "atom-tools", :lib => 'atom/service', :version => '>= 2.0.1'
config.gem "hpricot", :version => '>= 0.6'
config.gem "mislav-will_paginate", :lib => 'will_paginate', 
                                   :version => '>= 2.3.2',
                                   :source => 'http://gems.github.com/'
config.gem 'atd-calendar_date_select', :lib => 'calendar_date_select',
                                       :version => '>= 1.11.20090109', 
                                              :source => 'http://gems.github.com'

# Core Extensions
require 'move/core_ext'

# ActiveRecord
require 'active_record/acts_as'
ActiveRecord::Base.extend ActiveRecord::ActsAs

# Singular Agents
if SingularAgent.table_exists?
  SingularAgent
  Anonymous.current
  Anyone.current
end

# Mime Types
# Redefine Mime::ATOM to include "application/atom+xml;type=entry"
Mime::Type.register "application/atom+xml", :atom, [ "application/atom+xml;type=entry" ]
Mime::Type.register "application/atomsvc+xml", :atomsvc
Mime::Type.register "application/atomcat+xml", :atomcat
Mime::Type.register "application/xrds+xml",    :xrds

# ActionController
for mod in [ ActionController::Move, ActionController::Authentication, ActionController::Authorization ]
  ActionController::Base.send(:include, mod) unless ActionController::Base.ancestors.include?(mod)
end

# ActionView
%w( categories performances logotype ).each do |item|
  require "action_view/helpers/form_#{ item }_helper"
  ActionView::Base.send :include, "ActionView::Helpers::Form#{ item.camelcase }Helper".constantize
end

# Inflections
ActiveSupport::Inflector.inflections do |inflect|
  inflect.uncountable 'cas'
  inflect.uncountable 'anonymous'
end

# Preload Models
file_patterns = [ RAILS_ROOT, File.dirname(__FILE__) ].map{ |f| f + '/app/models/**/*.rb' }
file_exclusions = ['svn', 'CVS', 'bzr']

file_patterns.each do |file_pattern|
  Dir[file_pattern].each do |filename|
    next if filename =~ /#{file_exclusions.join("|")}/
    open filename do |file|
      begin
        require_dependency(filename) if file.grep(/acts_as_(#{ ActiveRecord::ActsAs::Features.join('|') })/).any?
      rescue Exception => e
        #FIXME: logger ?
        puts "CMSplugin autoload: Couldn't load file #{ filename }: #{ e }"
      end
    end
  end
end
