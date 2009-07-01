class Station2To3 < ActiveRecord::Migration
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
   end
 
  def self.down
    drop_table :admissions
  end
end
