module CMS
  class AttachmentFu < ActiveRecord::Base
    set_table_name "cms_attachment_fus"

    has_attachment 
    # Fix attachment_fu constant problem
    belongs_to  :db_file, :class_name => 'DbFile', :foreign_key => 'db_file_id'
    
    validates_as_attachment

    alias_attribute :media, :uploaded_data
    
    def self.atom_entry_filter(entry)
      # Example:
      #     # { :body => entry.content.xml.to_s }
      #         {}
      #
    end
  end
end
