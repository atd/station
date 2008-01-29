# Entry can be rendered from a feed or stand-alone
# If alone, it has to define XML namespaces
defined_namespaces ||= false

namespaces = ( defined_namespaces ? {} : { "xmlns" => 'http://www.w3.org/2005/Atom', "xmlns:app" => 'http://www.w3.org/2007/app' } )

xml.entry namespaces do

  xml.title(:type => "xhtml") do
    xml.div(:xmlns => "http://www.w3.org/1999/xhtml") do
      xml << sanitize(post.title)
    end
  end

  xml.author do
    xml.name(post.agent.name)
    xml.uri(polymorphic_url(post.agent, :only_path => false))
  end

  xml.id("tag:#{ controller.request.host_with_port },#{ post.updated_at.year }:#{ url_for(post) }")
  xml.published(post.created_at.xmlschema)
  xml.updated(post.updated_at.xmlschema)
  xml.tag!("app:edited", post.updated_at.xmlschema)
  xml.link(:rel => 'alternate', :type => 'text/html', :href => polymorphic_url(post, :only_path => false))
  xml.link(:rel => 'edit', :href => "#{ polymorphic_url(post, :only_path => false) }.atom_entry")
  xml.link(:rel => 'edit-media', :href => "#{ polymorphic_url(post, :only_path => false) }.#{ content.mime_type.to_sym }") if post.content.methods.include?("disposition")

  xml.summary(:type => "xhtml") do
    xml.div(:xmlns => "http://www.w3.org/1999/xhtml") do
      xml << sanitize(content.description)
    end
  end if post.description

  xml << render(:partial => "#{ content.class.to_s.tableize }/entry",
                :locals  => { :content => post.content })

end
