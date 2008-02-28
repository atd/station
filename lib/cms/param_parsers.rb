# Param Parsers for AtomPub. 
# Param Parsers allow data preprocessing in REST web services
# See ActionController::Base.param_parsers for more details

require 'atom/entry'

# Redefine Mime::ATOM to include "application/atom+xml;type=entry"
Mime::Type.register "application/atom+xml", :atom, [ "application/atom+xml;type=entry" ]

# Atom Entry ParamParser
ActionController::Base.param_parsers[Mime::ATOM] = Proc.new do |data|
  entry = Atom::Entry.parse(data)

  post = HashWithIndifferentAccess.new
  post["title"]       = entry.title.xml.to_s
  post["description"] = entry.summary.xml.to_s if entry.summary
  post["public_read"] = "1" unless entry.draft

  # Watch ContentsController.complete_file_data method when implementing this!

  content = HashWithIndifferentAccess.new
  content["atom_entry"] = data

  # Parse usual parameters

  # "The value "related" signifies that the IRI in the value of the
  # href attribute identifies a resource related to the resource
  # described by the containing element." (RFC 4287)
  content["url"] = entry.links.select{ |l| l["rel"] == "related" }.first 
  # "The value "alternate" signifies that the IRI in the value of the
  # href attribute identifies an alternate version of the resource
  # described by the containing element." (RFC 4287)
  content["url"] ||= entry.links.select{ |l| l["rel"] == "alternate" }.first
  # Get actual URL
  content["url"] = content["url"]["href"] if content["url"]

  # TODO binnary content, src content
  content["content"] = entry.content.xml.to_s if entry.content

  { "post" => post, "content" => content }
end


# Attachment Contents' Mime Types
# Set a Proc for each type, so the attachment POSTed or PUTed is converted to
# params[:content][:uploaded_data] (for attachment_fu)
# TODO: other attachment plugins like file_column

CMS.content_classes.select{ |c| c.content_options[:has_media]}.each do |klass|
  for content_type in Mime::Type.parse(klass.content_options[:atompub_mime_types]).reject{ |c| c == MimeType::ATOM }
    ActionController::Base.param_parsers[content_type] = Proc.new do |data|
      original_filename = send("request").env["HTTP_SLUG"] || "#{ send('controller_name').singularize }.#{ content_type.to_sym.to_s }"
      file = Tempfile.new("file")
      file.write data
      (class << file; self; end).class_eval do
        alias local_path path
        define_method(:content_type) { content_type.dup.taint }
        define_method(:original_filename) { original_filename.dup.taint }
      end
      { "post"    => { "title" => original_filename }, 
        "content" => { "uploaded_data" => file }
      }
    end if content_type.instance_variable_get("@symbol") # If the content_type is registered
  end
end

