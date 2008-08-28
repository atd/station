class <%= controller_class_name %>Controller < ApplicationController
  # Include some methods and filters.
  include CMS::Controller::Contents
  
  # Authentication Filter
  before_filter :authentication_required, :except => [ :index, :show ]
  
  # Needs a Container when posting a new <%= controller_class_name.singularize %>
  before_filter :needs_container, :only => [ :new, :create ]
      
  # Get <%= controller_class_name.singularize %> in member actions
  before_filter :get_content, :except => [ :index, :new, :create ]
end
