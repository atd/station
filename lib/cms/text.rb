module CMS
  class Text < ActiveRecord::Base
    set_table_name "cms_texts"

    validates_presence_of :text

    def self.atom_entry_filter(entry)
      { :text => entry.content.xml.to_s }
    end
  end
end
