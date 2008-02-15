xml.instruct!
xml.service "xmlns" => "http://www.w3.org/2007/app", "xmlns:atom" => 'http://www.w3.org/2005/Atom' do
  # Workspaces are Container this Agent can post to:
  for container in current_agent.post_containers
    xml.workspace do
      xml.tag!( "atom:title", container.name )
      # Collections are different type of Contents
      for content in container.contents
        xml.collection ( :href => send("container_#{ content }_url", :container_type => container.class.to_s.tableize, :container_id => container.id) + '.atom' ) do
          xml.tag!("atom:title", "#{ container.name } - #{ content.to_class.collection }")
          xml.accept(content.to_class.mime_types)
        end
      end
    end
  end
end
