module MenuBoxHelper
  def menu_box(symbol, &block)

    block ||= lambda { |item|
      "#{ link_to(icon_image(item, :alt => item.name + ' logo'), item) }<span class=\"box_unit_title\">#{ link_to item.name, item }</span>"
    }

    returning "" do |html|
      html << <<-"end_html"
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
            <span class="box_title">#{ t(symbol.to_s.singularize, :count => :other) }</span>
            <div class="box_view_wrapper" id="#{ symbol }_wrapper">
              <div class="box_view_list" id="#{ symbol }_list">
      end_html
              #{ menu_box_items(symbol, options) }
      items = instance_variable_get("@#{ symbol }") || Array.new

      items.inject html do |html, item|
        html << "<div class=\"box_unit\">"
        html << yield(item)
#        html << send(link_method, image_tag(icon_image(item), :alt => item.name + " logo"), 
#        html << "<span class=\"box_unit_title\">#{ link_to item.name, item }</span>"
        html << "</div>"
      end

      html << <<-"end_html"
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
  end
end
