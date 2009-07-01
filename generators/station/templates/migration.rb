class StationMigration < ActiveRecord::Migration
  def self.up
    create_table :admissions do |t|
      t.string     :type
      t.references :candidate,  :polymorphic => true
      t.references :group,      :polymorphic => true
      t.references :introducer, :polymorphic => true
      t.string     :email
      t.references :role
      t.text       :comment
      t.string     :code
      t.boolean    :accepted

      t.timestamps
      t.datetime   :processed_at
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
      t.integer  :domain_id
      t.string   :domain_type
      t.integer  :parent_id
      t.datetime :created_at
      t.datetime :updated_at
    end

    create_table :categorizations, :force => true do |t|
      t.integer :category_id
      t.integer :categorizable_id
      t.string  :categorizable_type
    end

    create_table :db_files, :force => true do |t|
      t.binary :data
    end

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

    create_table :logos do |t|
      t.integer  :logoable_id
      t.string   :logoable_type
      t.integer  :size
      t.string   :content_type
      t.string   :filename
      t.integer  :height
      t.integer  :width
      t.integer  :parent_id
      t.string   :thumbnail
      t.integer  :db_file_id

      t.timestamps
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

    create_table :open_id_ownings do |t|
      t.integer :agent_id
      t.string  :agent_type
      t.integer :uri_id
    end

    create_table :open_id_trusts do |t|
      t.integer :agent_id
      t.string  :agent_type
      t.integer :uri_id
      t.boolean :local, :default => false
    end


    create_table :performances do |t|
      t.integer :agent_id
      t.string  :agent_type
      t.integer :stage_id
      t.string  :stage_type
      t.integer :role_id
    end

    create_table :permissions do |t|
      t.string :action
      t.string :objective
    end

    create_table :permissions_roles, :id => false do |t|
      t.integer :permission_id
      t.integer :role_id
    end

    create_table :posts do |t|
      t.text :content
      t.integer :parent_id
      t.timestamps
    end

    create_table :roles do |t|
      t.string :name
      t.string :stage_type
    end

    create_table :singular_agents do |t|
      t.column :type, :string
    end

    create_table :sites do |t|
      t.string :name, :default => 'Station powered Rails site'
      t.text   :description
      t.string :domain, :default => 'station.example.org'
      t.string :email, :default => 'admin@example.org'
      t.boolean :ssl, :default => false
      t.boolean :exception_notifications, :default => false
      t.string :exception_notifications_email
      t.timestamps
    end

    create_table :uris do |t|
      t.string :uri
    end
    add_index :uris, :uri
  end

  def self.down
    drop_table :admissions
    drop_table :attachments
    drop_table :categories
    drop_table :categorizations
    drop_table :db_files
    drop_table :invitations
    drop_table :logos
    drop_table :open_id_associations
    drop_table :open_id_nonces
    drop_table :open_id_ownings
    drop_table :open_id_trusts
    drop_table :performances
    drop_table :permissions
    drop_table :permissions_roles
    drop_table :posts    
    drop_table :roles
    drop_table :singular_agents
    drop_table :sites
    drop_table :uris
  end
end
