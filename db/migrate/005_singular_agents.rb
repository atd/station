class SingularAgents < ActiveRecord::Migration
  def self.up
    create_table :singular_agents do |t|
      t.column :type, :string
    end
    drop_table :anonymous_agents
  end

  def self.down
    create_table :anonymous_agents do |t|
    end
    drop_table :singular_agents
  end
end
