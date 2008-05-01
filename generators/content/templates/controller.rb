class <%= controller_class_name %>Controller < ApplicationController
  # Include some methods and filters.
  include CMS::Controller::Contents
  
  # Authentication Filter
  before_filter :authentication_required, :except => [ :index, :show ]
  
  # <%= controller_class_name %> list may belong to a container
  # /<%= controller_class_name.tableize %>
  # /:container_type/:container_id/<%= controller_class_name.tableize %>
  before_filter :get_container, :only => [ :index ]

  # Needs a Container when posting a new <%= controller_class_name.singularize %>
  before_filter :needs_container, :only => [ :new, :create ]
      
  # Get <%= controller_class_name.singularize %> in member actions
  before_filter :get_content, :except => [ :index, :new, :create ]
end
