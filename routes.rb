resource :site do |site|
  site.resources :entries, :categories
  site.resources *CMS.contents
end

open_id_complete 'session', 
  { :controller => 'sessions', 
    :action     => 'create',
    :conditions => { :method => :get },
    :open_id_complete => true }

resource :session

login 'login',   :controller => 'sessions', :action => 'new'
logout 'logout', :controller => 'sessions', :action => 'destroy'

if CMS::Agent.activation_class
  activate 'activate/:activation_code', 
           :controller => CMS::Agent.activation_class.to_s.tableize, 
           :action => 'activate', 
           :activation_code => nil
  forgot_password 'forgot_password', 
                  :controller => CMS::Agent.activation_class.to_s.tableize,
                  :action => 'forgot_password'
  reset_password 'reset_password/:reset_password_code', 
                 :controller => CMS::Agent.activation_class.to_s.tableize,
                 :action => 'reset_password',
                 :reset_password_code => nil
end

resources :entries, :member => { :media => :any,
                               :edit_media => :get,
                               :details => :any }
resources :categories

resources *((CMS.contents | CMS.agents) - CMS.containers)

resources(*(CMS.containers) - Array(:sites)) do |container|
  container.resources(*CMS.contents)
  container.resources :entries, :categories
end

