# A migration to set needed tables for CMS support

class CmsSetup < ActiveRecord::Migration
  def self.up
    create_table :posts do |t|
      t.string   :title
      t.text     :description
      t.timestamps
      t.integer  :container_id
      t.string   :container_type
      t.integer  :author_id
      t.string   :author_type
      t.integer  :content_id
      t.string   :content_type
      t.integer  :parent_id
      t.string   :parent_type
      t.boolean  :public_read
      t.boolean  :public_write
    end

    create_table :uris do |t|
      t.string :uri
    end
    add_index :uris, :uri
  end

  def self.down
    drop_table :posts
    drop_table :uris
  end
end
