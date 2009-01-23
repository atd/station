class CreateInvitations < ActiveRecord::Migration
  def self.up
    create_table :invitations do |t|
      t.column :code, :string
      t.column :email, :string
      t.column :agent_id, :integer
      t.column :agent_type, :string
      t.column :stage_id, :integer
      t.column :stage_type, :string
      t.column :role_id, :integer
      t.column :acceptation_code, :string
      t.column :accepted_at, :datetime

      t.timestamps
    end
  end

  def self.down
    drop_table :invitations
  end
end
