# Agents using OpenID authentication verify their OpenID URLs when singing in
#
# CMS::OpenID::Owning class stores the relation between the agent and the verified
# Uri
class CMS::OpenID::Owning < ActiveRecord::Base
  set_table_name "open_id_ownings"

  belongs_to :agent, :polymorphic => true
  belongs_to :uri

  validates_presence_of :agent_id, :agent_type, :uri_id
end
