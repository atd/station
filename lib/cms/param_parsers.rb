# Param Parsers for AtomPub. 
# Param Parsers allow data preprocessing in REST web services
# See ActionController::Base.param_parsers for more details

require 'atom/entry'
require 'cms/mime_types'

module CMS
  def self.enable_param_parsers
    # Atom Entry ParamParser
    ActionController::Base.param_parsers[Mime::ATOM] = Proc.new do |data|
      atom_entry = Atom::Entry.parse(data)

      entry = HashWithIndifferentAccess.new
      entry["title"]       = atom_entry.title.xml.to_s
      entry["description"] = atom_entry.summary.xml.to_s if atom_entry.summary
      entry["public_read"] = "1" unless atom_entry.draft

      content = HashWithIndifferentAccess.new
      content["atom_entry"] = data

      { "entry" => entry, "content" => content }
    end
  end
end

