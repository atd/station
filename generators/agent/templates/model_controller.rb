class <%= model_controller_class_name %>Controller < ApplicationController
  # Include some methods and filters. 
  include CMS::ActionController::Agents
  
  # Get the <%= model_controller_class_name.singularize %> for member actions
  before_filter :get_agent, :only => :show
  
  # Filter for activation actions
  before_filter :activation_required, :only => [ :activate, 
                                                 :forgot_password, 
                                                 :reset_password ]
  # Filter for password recovery actions
  before_filter :login_and_pass_auth_required, :only => [ :forgot_password,
                                                          :reset_password ]
  
end
