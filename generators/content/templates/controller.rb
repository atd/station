class <%= controller_class_name %>Controller < ApplicationController
  # Include some methods and filters.
  include ActionController::Contents
  
  # Needs a Container when posting a new <%= controller_class_name.singularize %>
  before_filter :needs_container, :only => [ :new, :create ]
      
  # Get <%= controller_class_name.singularize %> in member actions
  before_filter :get_content, :only => [ :show ]
end
