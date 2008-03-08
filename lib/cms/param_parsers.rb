# Param Parsers for AtomPub. 
# Param Parsers allow data preprocessing in REST web services
# See ActionController::Base.param_parsers for more details

require 'atom/entry'
require 'cms/mime_types'

module CMS
  def self.enable_param_parsers
    # Atom Entry ParamParser
    ActionController::Base.param_parsers[Mime::ATOM] = Proc.new do |data|
      entry = Atom::Entry.parse(data)

      post = HashWithIndifferentAccess.new
      post["title"]       = entry.title.xml.to_s
      post["description"] = entry.summary.xml.to_s if entry.summary
      post["public_read"] = "1" unless entry.draft

      content = HashWithIndifferentAccess.new
      content["atom_entry"] = data

      { "post" => post, "content" => content }
    end
  end
end

