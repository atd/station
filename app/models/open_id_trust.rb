# Agents with OpenID Server have OpenID trusts when approve sign in a Remote Server
#
class OpenIdTrust < ActiveRecord::Base
  belongs_to :agent, :polymorphic => true
  belongs_to :uri

  validates_presence_of :agent_id, :agent_type, :uri_id
end
