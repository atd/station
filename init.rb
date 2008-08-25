config.gem "ruby-openid", :lib => 'openid', :version => '>= 2.0.4'
config.gem "atom-tools", :lib => 'atom/service', :version => '>= 2.0.1'
config.gem "hpricot", :version => '>= 0.6'
config.gem "mislav-will_paginate", :lib => 'will_paginate', 
                                   :version => '>= 2.3.2',
                                   :source => 'http://gems.github.com/'

config.after_initialize do
  # Controllers
  ActionController::Base.send(:include, CMS::Controller::Base)
  ActionController::Base.send(:include, CMS::Controller::Authentication)
end

unless defined? CMS
  require 'cms'
  CMS.enable
end
