module CMS
  class AttachmentFu < ActiveRecord::Base
    set_table_name "cms_attachment_fus"

    has_attachment 
    
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
