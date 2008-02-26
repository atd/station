class <%= class_name %> < ActiveRecord::Base
  # Fill atom_mapping for AtomPub support
  acts_as_content :atom_mapping => {}
end
