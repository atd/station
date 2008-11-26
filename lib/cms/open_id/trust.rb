# Agents with OpenID Server have OpenID trusts when approve sign in a Remote Server
#
class CMS::OpenID::Trust < ActiveRecord::Base
  set_table_name "open_id_trusts"

  belongs_to :agent, :polymorphic => true
  belongs_to :uri

  validates_presence_of :agent_id, :agent_type, :uri_id
end
