# Require Ruby URI Module, not defined by this file but with the 
# same source file name
URI

{ 'openid' => 'OpenID',
  'atom/service' => 'AtomPub service document' }.each_pair do |gem, support|
  begin
    require gem
  rescue MissingSourceFile
    Rails.logger.info "Station Info: You need '#{ gem }' gem for #{ support } support"
  end
end

# URI storage in the database
class Uri < ActiveRecord::Base
  has_many :openid_ownings, 
           :class_name => "OpenIdOwning"
  has_many :openid_trusts,
           :class_name => "OpenIdTrust"
             
  # Return this URI string         
  def to_s
    self.uri
  end

  def to_uri
    @to_uri ||= ::URI.parse(self.uri)
  end

  # Dereference URI and return HTML document
  def html
    # NOTE: Must read StringIO or Tmpfile
    @html ||= Station::Html.new(dereference(:accept => 'text/html').try(:read))
  end

  def dereference(options = {})
    headers = {}
    headers['Accept'] = options[:accept] if options.key?(:accept)

    to_uri.open(headers)
  rescue
    nil
  end

  # Perform OpenID discover
  #
  # OpenID.discover returns [ claimed_id, openid_services ]
  def openid_discover
    @openid_discover ||= ::OpenID.discover self.uri
  end

  # Is this URI an OpenID
  def openid?
    openid_discover.last.any?
  rescue
    nil
  end

  # Update self.uri with OpenID claimed ID
  def to_openid
    self.uri = openid_discover.first
  end

  # Update self.uri with OpenID claimed ID and save the record
  def to_openid!
    update_attribute :uri, openid_discover.first
  end

  # Returns all the XRDS Service Endpoint Types 
  def xrds_service_types
    openid_discover.last.select{ |s| s.used_yadis }.map{ |s| s.type_uris }.flatten.uniq
  rescue
    Array.new
  end

  # Returns the AtomPub Service Document associated with this URI.
  def atompub_service_document
    #FIXME: use html?
    Atom::Service.discover self.uri
  end

  delegate :hcard, :hcard?,
           :foaf, :foaf?,
           :to => :html

  private

  # Extract service link from HTML head
  def parse_atompub_service_link(html) #:nodoc:
    # TODO: link service
    # TODO: meta refresh
    nil
  end
end
