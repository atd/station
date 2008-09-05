# A migration to set needed tables for CMS support

class Init < ActiveRecord::Migration
  def self.up
    create_table :anonymous_agents do |t|
    end

    create_table :attachments do |t|
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

    create_table :categories, :force => true do |t|
      t.string   :name
      t.text     :description
      t.integer  :container_id
      t.string   :container_type
      t.integer  :parent_id
      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :categorizations, :force => true do |t|
      t.integer :category_id
      t.integer :entry_id
    end

    create_table :performances do |t|
      t.integer :agent_id
      t.string  :agent_type
      t.integer :role_id
      t.integer :container_id
      t.string  :container_type
    end

    create_table :entries do |t|
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

    create_table :roles do |t|
      t.string :name
      t.boolean :admin
      t.boolean :create_entries
      t.boolean :read_entries
      t.boolean :update_entries
      t.boolean :delete_entries
      t.boolean :create_performances
      t.boolean :read_performances
      t.boolean :update_performances
      t.boolean :delete_performances
    end

    create_table :sites do |t|
      t.string :name, :default => 'CMSplugin powered Rails site'
      t.text   :description
      t.string :domain, :default => 'cms.example.org'
      t.string :email, :default => 'admin@example.org'
      t.string :locale
      t.timestamps
    end

    create_table :xhtml_texts do |t|
      t.string :type
      t.text :text
      t.timestamps
    end

    create_table :uris do |t|
      t.string :uri
    end
    add_index :uris, :uri

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
    drop_table :anonymous_agents
    drop_table :attachments
    drop_table :categories
    drop_table :categorizations
    drop_table :performances
    drop_table :entries
    drop_table :roles
    drop_table :xhtml_texts    
    drop_table :uris
    drop_table :open_id_ownings
    drop_table :open_id_associations
    drop_table :open_id_nonces
  end
end
