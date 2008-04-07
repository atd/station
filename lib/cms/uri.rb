module CMS
  # URI storage in the database
  class URI < ActiveRecord::Base
    set_table_name "cms_uris"

    has_many :openid_ownings, 
             :class_name => "CMS::OpenID::Owning"
             
    # Return this URI string         
    def to_s
      self.uri
    end
  end
end
