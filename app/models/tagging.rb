class Tagging < ActiveRecord::Base 
 
  belongs_to :tag, :counter_cache => true
  belongs_to :taggable, :polymorphic => true
  
  # If you also need to use <tt>acts_as_list</tt>, you will have to manage the tagging positions manually by creating decorated join records when you associate Tags with taggables.
  # acts_as_list :scope => :taggable
    
  # This callback makes sure that an orphaned <tt>Tag</tt> is deleted if it no longer tags anything.
  def after_destroy
    tag.destroy_without_callbacks if tag and tag.taggings.count == 0
  end    
end
