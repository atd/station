module CategoriesHelper
  # Render a form for Categories
  def categories_form(container = nil)
    container ||= current_container || Site.current
    render :partial => "categories/categories_form", 
           :locals => { :container => container }
  end

  # Return a list of linked Categories, separated by <tt>,</tt>
  def categories_list(item)
    item.categories.map{ |c|
      link_to c.name, polymorphic_path([ c.container, c ])
    }.join(', ')
  end
end
