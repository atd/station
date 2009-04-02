class Logoables < ActiveRecord::Migration
  def self.up
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
  end

  def self.down
    drop_table :logos
  end
end
