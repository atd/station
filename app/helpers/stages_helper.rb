module StagesHelper

  def performances_form(stage, form)
    roles = stage.class.roles + Role.without_stage_type
    render :partial => "stages/perfomances_form", 
           :locals => { :stage => stage, :roles => roles, :form => form }
  end

end