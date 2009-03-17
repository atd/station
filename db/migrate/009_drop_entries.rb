class DropEntries < ActiveRecord::Migration
  def self.up
    drop_table :entries
  end

  def self.down
    create_table :entries do |t|
      t.string   :title
      t.text     :description
      t.datetime :created_at
      t.datetime :updated_at
      t.integer  :container_id
      t.string   :container_type
      t.integer  :agent_id
      t.string   :agent_type
      t.integer  :content_id
      t.string   :content_type
      t.integer  :parent_id
      t.string   :parent_type
      t.boolean  :public_read
      t.boolean  :public_write
    end
  end
end
