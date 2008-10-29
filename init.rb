config.gem "ruby-openid", :lib => 'openid', :version => '>= 2.0.4'
config.gem "atom-tools", :lib => 'atom/service', :version => '>= 2.0.1'
config.gem "hpricot", :version => '>= 0.6'
config.gem "mislav-will_paginate", :lib => 'will_paginate', 
                                   :version => '>= 2.3.2',
                                   :source => 'http://gems.github.com/'
config.gem 'artmotion-calendar_date_select', :lib => 'gem_init',
                                              :version => '1.10.9', 
                                              :source => 'http://gems.github.com'

config.after_initialize do
  # Controllers
  for mod in [ CMS::Controller::Base, CMS::Controller::Authentication, CMS::Controller::Authorization ]
    ActionController::Base.send(:include, mod) unless ActionController::Base.ancestors.include?(mod)
  end

  CMS.inflections
end

unless defined? CMS
  require 'cms'
  CMS.enable
end
