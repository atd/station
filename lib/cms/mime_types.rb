# CMS Mime Types

module CMS
  def self.enable_mime_types
    # Redefine Mime::ATOM to include "application/atom+xml;type=entry"
    Mime::Type.register "application/atom+xml", :atom, [ "application/atom+xml;type=entry" ]

    Mime::Type.register "application/atomsvc+xml", :atomsvc
    Mime::Type.register "application/atomcat+xml", :atomcat
    Mime::Type.register "application/xrds+xml",    :xrds
  end
end
