module CMS
  # Posts are CRUDed Contents
  # (CRUD: http://en.wikipedia.org/wiki/Create,_read,_update_and_delete)
  #
  # A Post is created when an Agent posts a Content to a Container
  class Post < ActiveRecord::Base
    # Collection name
    # See CMS::Content
    cattr_reader :collection
    @@collection = :posts

    belongs_to :content,   :polymorphic => true
    belongs_to :container, :polymorphic => true
    belongs_to :agent,     :polymorphic => true

    validates_presence_of :title, 
                          :agent_id,
                          :agent_type,
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
