module ResourcesHelper
  def resource_info(resource = nil)
    resource ||= @resource

    returning "" do |html|
      html <<  "<div id=\"content_info_top\" class=\"block_white_top\">» #{ t('detail.other') } </div>"
      html << "<div id=\"content_info_center\" class=\"block_white_center\">#{ render(:partial => "resources/info", :locals => { :resource => resource } ) if resource }</div>"
      html << "<div id=\"content_info_bottom\" class=\"block_white_bottom\"></div>"
    end
  end
end
