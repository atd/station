class CMS::OpenID::Owning < ActiveRecord::Base
  set_table_name "open_id_ownings"

  belongs_to :agent, :polymorphic => true
  belongs_to :uri, :class_name => "CMS::URI"

  validates_presence_of :agent_id, :agent_type, :uri_id
end
