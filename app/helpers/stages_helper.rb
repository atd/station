module StagesHelper

  def performances_form(stage)
    roles = stage.class.roles + Role.without_stage_type
    returning "" do |html|
      html << "<div id=\"performance_form_#{ dom_id stage }\" class=\"performance_forms\">"
      html << "#{ roles.map(&:name) }de<br />"
      html << "</div>"
    end
  end

end