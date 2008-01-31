class <%= class_name %> < ActiveRecord::Base
  acts_as_agent :authentication => [ :login_and_password ],
                :activation => <%= options[:include_activation] %>
  acts_as_container
end
