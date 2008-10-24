module CategoriesHelper
  # Render a form for Categories
  def categories_form(container = nil)
    container ||= current_container || Site.current

    returning "" do |html|
      html << '<p id="categories_form">'
      html << "<b>#{ 'Category'.t('Categories', 99) }</b><br />"

      html << '<div id="categories_list">'
      if container.container_categories.blank?
        html << "%s has not categories" / sanitize(container.name)
      else 
        container.container_categories.each do |c|
          html << check_box_tag('category_ids[]', c.id, (params[:category_ids] || []).map(&:to_i).include?(c.id)) + sanitize(c.name) + '<br />'
        end
      end 
      html << '</div>'
      html << link_to_remote("New Category", 
                             :url => polymorphic_path([ container, Category.new ]),
                             :with => "'category[name]=' + window.prompt('#{ 'Category name'.t }')",
			     { :id => "new_category", :class => "action add"} )
                                 
      html << '</p>'
    end
  end

  # Return a list of linked Categories, separated by <tt>,</tt>
  def categories_list(item)
    item.categories.map{ |c|
      link_to c.name, polymorphic_path([ c.container, c ])
    }.join(', ')
  end
end
