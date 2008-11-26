module CategoriesHelper
  # Return a list of linked Categories, separated by <tt>,</tt>
  def categories_list(item)
    item.categories.map{ |c|
      link_to c.name, polymorphic_path([ c.domain, c ])
    }.join(', ')
  end
end
