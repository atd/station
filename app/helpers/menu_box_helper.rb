module MenuBoxHelper
  def menu_box(symbol)
    <<-"end_html"
  <div id="#{ symbol }">
    <div id="#{ symbol }_top"></div>
    <div id="#{ symbol }_center">
      <div id="#{ symbol }_center_inside">
         <!-- menu box #{ symbol } -->
        <div id="menu_box_#{ symbol }">
          <!-- menu box #{ symbol } left botton, close it -->
          <div class="box_botton_left" onmouseover="setStateMove(1,'left','#{ symbol }');" onmouseout="setStateMove(0,'left','#{ symbol }');" id="#{ symbol }_botton_left"></div>
          <!-- menu box #{ symbol } view container  -->
          <div class="box_view_container">
            <span class="box_title">#{ symbol.to_s.humanize.singularize.t(symbol.to_s.humanize.pluralize, 99) }</span>
            <div class="box_view_wrapper" id="#{ symbol }_wrapper">
              <div class="box_view_list" id="#{ symbol }_list">
              #{ menu_box_items(symbol) }
              </div>
            </div>
          </div>
          <!-- menu box #{ symbol } right botton, close it -->
          <div class="box_botton_right"  onmouseover="setStateMove(1,'right','#{ symbol }');" onmouseout="setStateMove(0,'right','#{ symbol }');" id="#{ symbol }_botton_right"></div>
        <!-- close menu box #{ symbol } -->
        </div>
      </div>
    </div>
    <div id="#{ symbol }_bottom"></div>
  </div>
    end_html
  end

  def menu_box_items(symbol)
    items = instance_variable_get("@#{ symbol }") || Array.new
    returning "" do |html|
      items.inject html do |html, item|
        html << "<div class=\"box_unit\">"
        html << link_to(image_tag(icon_image(item), :alt => item.name + " logo"), item)
        html << "<span class=\"box_unit_title\">#{ link_to item.name, item }</span>"
        html << "</div>"
      end
    end
  end
end
