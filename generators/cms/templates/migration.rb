# A migration to set needed tables for CMS support

class CmsSetup < ActiveRecord::Migration
  def self.up
    create_table :cms_categories, :force => true do |t|
      t.string   :name
      t.text     :description
      t.integer  :container_id
      t.string   :container_type
      t.integer  :parent_id
      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :cms_categorizations, :force => true do |t|
      t.integer :category_id
      t.integer :post_id
    end

    create_table :cms_posts do |t|
      t.string   :title
      t.text     :description
      t.timestamps
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

    create_table :cms_attachment_fus do |t|
      t.string   :type
      t.integer  :size
      t.string   :content_type
      t.string   :filename
      t.integer  :height
      t.integer  :width
      t.integer  :parent_id
      t.string   :thumbnail
      t.integer  :db_file_id
      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :cms_uris do |t|
      t.string :uri
    end
    add_index :cms_uris, :uri

    create_table :cms_roles do |t|
      t.string :name
      t.boolean :admin
      t.boolean :create_posts
      t.boolean :read_posts
      t.boolean :update_posts
      t.boolean :delete_posts
      t.boolean :create_performances
      t.boolean :read_performances
      t.boolean :update_performances
      t.boolean :delete_performances
    end

    create_table :cms_performances do |t|
      t.integer :agent_id
      t.string  :agent_type
      t.integer :role_id
      t.integer :container_id
      t.string  :container_type
    end

    create_table :open_id_ownings do |t|
      t.integer :agent_id
      t.string  :agent_type
      t.integer :uri_id
    end

    create_table :open_id_associations, :force => true do |t|
      t.binary  :server_url
      t.string  :handle
      t.binary  :secret
      t.integer :issued
      t.integer :lifetime
      t.string  :assoc_type
    end

    create_table :open_id_nonces, :force => true do |t|
      t.string  :server_url, :null => false
      t.integer :timestamp,  :null => false
      t.string  :salt,       :null => false
    end
  end

  def self.down
    drop_table :cms_categories
    drop_table :cms_categorizations
    drop_table :cms_posts
    drop_table :cms_attachment_fus
    drop_table :cms_uris
    drop_table :cms_roles
    drop_table :cms_performances
    drop_table :open_id_ownings
    drop_table :open_id_associations
    drop_table :open_id_nonces
  end
end
