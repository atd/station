# CMS Mime Types

module CMS
  def self.enable_mime_types
    # Redefine Mime::ATOM to include "application/atom+xml;type=entry"
    Mime::Type.register "application/atom+xml", :atom, [ "application/atom+xml;type=entry" ]

    Mime::Type.register "application/atomsvc+xml", :atomsvc
    Mime::Type.register "application/atomcat+xml", :atomcat
    Mime::Type.register "application/xrds+xml",    :xrds

    # Include Application MimeTypes
    # FIXME: this is necessary for CMS.param_parsers load
    # but introduces warnings when loaded by Rails Initializers
    load RAILS_ROOT + '/config/initializers/mime_types.rb'
  end
end
