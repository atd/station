openid_server 'openid_server', :controller => 'openid_server'

open_id_complete 'session', 
  { :controller => 'sessions', 
    :action     => 'create',
    :conditions => { :method => :get },
    :open_id_complete => true }

resource :session

login 'login',   :controller => 'sessions', :action => 'new'
logout 'logout', :controller => 'sessions', :action => 'destroy'

if CMS::ActiveRecord::Agent.activation_class
  activate 'activate/:activation_code', 
           :controller => CMS::ActiveRecord::Agent.activation_class.to_s.tableize, 
           :action => 'activate', 
           :activation_code => nil
  forgot_password 'forgot_password', 
                  :controller => CMS::ActiveRecord::Agent.activation_class.to_s.tableize,
                  :action => 'forgot_password'
  reset_password 'reset_password/:reset_password_code', 
                 :controller => CMS::ActiveRecord::Agent.activation_class.to_s.tableize,
                 :action => 'reset_password',
                 :reset_password_code => nil
end

resources :entries, :member => { :media => :any,
                               :edit_media => :get,
                               :details => :any }
resources :categories

resource :site do |site|
  site.resources :entries, :categories
  site.resources *CMS::ActiveRecord::Content.symbols
end

resources *((CMS::ActiveRecord::Content.symbols | CMS::ActiveRecord::Agent.symbols) - CMS::ActiveRecord::Container.symbols)

resources(*(CMS::ActiveRecord::Container.symbols) - Array(:sites)) do |container|
  container.resources(*CMS::ActiveRecord::Content.symbols)
  container.resources :entries, :categories
end

resources :logotypes

resources(*(CMS::ActiveRecord::Logotypable.symbols - Array(:sites))) do |logotypable|
  logotypable.resource :logotype
end

resources :roles
resources :invitations, :member => { :accept => :get }

resources(*CMS::ActiveRecord::Stage.symbols - Array(:sites)) do |stage|
  stage.resources :invitations
end

root :controller => 'entries'
