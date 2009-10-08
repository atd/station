atom_feed('xmlns:app' => 'http://www.w3.org/2007/app',
          :root_url => polymorphic_url([ current_container, <%= class_name %>.new ])) do |feed|

  feed.title(:type => "xhtml") do 
    feed.div(sanitize(title),:xmlns => "http://www.w3.org/1999/xhtml")
  end

  description = current_container && current_container.respond_to?(:description) && current_container.description
  description ||= current_site.description
  feed.subtitle(:type => "xhtml") do
    feed.div(sanitize(description), :xmlns => "http://www.w3.org/1999/xhtml")
  end if description.present? 

  feed.updated(@<%= table_name %>.first.updated_at || Time.now)

  @<%= table_name %>.each do |<%= singular_name %>|
    feed.entry(<%= singular_name %>, :url => polymorphic_url(<%= singular_name %>)) do |entry|
      render :partial => '<%= singular_name %>',
             :object => <%= singular_name %>,
             :locals => { :entry => entry }
    end
  end
end
