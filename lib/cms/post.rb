module CMS #nodoc#
  # Posts are CRUDed Contents
  # (CRUD: http://en.wikipedia.org/wiki/Create,_read,_update_and_delete)
  #
  # Contents are posted by Agents (the <tt>author</tt>) into Containers (<tt>container</tt>)
  class Post < ActiveRecord::Base
    belongs_to :content,   :polymorphic => true
    belongs_to :container, :polymorphic => true
    belongs_to :author,    :polymorphic => true

    validates_presence_of :title, 
                          :author_id,
                          :author_type,
                          :content_id, 
                          :content_type,
                          :container_id, 
                          :container_type
    validates_associated  :content

    # Can the Post be read by <tt>agent</tt>?
    def read_by?(agent = nil)
      return true if public_read?
      return false unless agent
      return true if container.has_owner?(agent)
    end

    # Can the Post be modified by <tt>agent</tt>?
    def write_by?(agent = nil)
      return true if public_write?
      return false unless agent
      return true if container.has_owner?(agent)
    end
  end
end
