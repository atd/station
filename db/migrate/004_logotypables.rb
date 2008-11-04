class Logotypables < ActiveRecord::Migration
  def self.up
    create_table :logotypes do |t|
      t.integer  :logotypable_id
      t.string   :logotypable_type
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
    drop_table :logotypes
  end
end
