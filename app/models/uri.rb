# Require Ruby URI Module, not defined by this file but with the 
# same source file name
URI

begin
  require 'atom/service'
rescue MissingSourceFile
  Rails.logger.info "Station Info: You need 'atom-tools' gem for AtomPub service document support"
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
    ::URI.parse(self.uri)
  end

  # Returns the AtomPub Service Document associated with this URI.
  # Only HTTP(S) URIs are supported:
  # * Dereference URI asking for +application/atomsvc+xml+ content type
  # * Search in the HTML document for "service" link
  def atompub_service_document(limit = 10)
    # Limit too many redirects
    return nil if limit == 0

    # TODO: non http(s) URIs
    return nil unless to_uri.scheme =~ /^(http|https)$/

    http = Net::HTTP.new(to_uri.host, to_uri.port)
    http.use_ssl = to_uri.scheme == "https"
    response = http.get(to_uri.path, 'Accept' => 'application/atomsvc+xml, text/html')
    case response
    when Net::HTTPSuccess
      case response.content_type.to_s
      when "application/atomsvc+xml"
        begin
          Atom::Service.parse(response.body)
        rescue
          nil
        end
      when "text/html"
        link_uri = parse_atompub_service_link(response.body)
        link_uri.blank? ? nil : self.class.new(:uri => link_uri).atompub_service_document(limit - 1)
      else
        nil
      end
    when Net::HTTPRedirection
      self.class.new(:uri => response['location']).atompub_service_document(limit - 1)
    else
      nil
    end
  end

  private

  # Extract service link from HTML head
  def parse_atompub_service_link(html) #:nodoc:
    # TODO: link service
    # TODO: meta refresh
    nil
  end
end
