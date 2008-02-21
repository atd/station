require 'cms/core_ext'
require 'cms/autoload'

module CMS
  ROUTES = <<-EORoutes
  map.resources :posts, :member => { :get => :edit_media,
                                     :put => :update_media }
  map.resources :posts, :path_prefix => '/:container_type/:container_id',
                        :name_prefix => 'container_'

  CMS.contents.each do |content|
      map.resources content
      map.resources content, :path_prefix => '/:container_type/:container_id',
                             :name_prefix => 'container_'
  end
  EORoutes

  class << self
    def enable
      enable_active_record
      enable_param_parsers
      self.autoload
    end

    def enable_active_record
      #FIXME: DRY
      require 'cms/agent'
      ActiveRecord::Base.send :include, Agent
      require 'cms/content'
      ActiveRecord::Base.send :include, Content
      require 'cms/container'
      ActiveRecord::Base.send :include, Container
    end

    # Param Parsers allow data preprocessing in REST web services. 
    # See ActionController::Base.param_parsers for more details
    def enable_param_parsers
      require 'cms/param_parsers'
    end

    # Return an Array with the class constants that act as an Agent
    def agent_classes
      @@agents.map{ |a| a.to_s.classify.constantize }
    end
  end
end
