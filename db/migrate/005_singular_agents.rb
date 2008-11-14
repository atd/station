class SingularAgents < ActiveRecord::Migration
  def self.up
    rename_table :anonymous_agents, :singular_agents
    add_column :singular_agents, :type, :string
  end

  def self.down
    remove_column :singular_agents, :type
    rename_table :singular_agents, :anonymous_agents
  end
end
