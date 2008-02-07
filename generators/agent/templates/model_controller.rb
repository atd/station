class <%= model_controller_class_name %>Controller < ApplicationController
  # Be sure to include CMS::Authentication in Application Controller instead
  include CMS::Authentication

  # render new.rhtml
  def new
    @<%= file_name %> = <%= class_name %>.new
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @<%= file_name %> = <%= class_name %>.new(params[:<%= file_name %>])
    @<%= file_name %>.openid_identifier = session[:openid_identifier]
    @<%= file_name %>.save!
    @<%= file_name %>.openid_ownings.create(:uri => CMS::URI.find_or_create_by_uri(session[:openid_identifier])) if session[:openid_identifier]
    self.current_agent = @<%= file_name %>
    redirect_back_or_default('/')
    flash[:notice] = "Thanks for signing up!"
  rescue ActiveRecord::RecordInvalid
    render :action => 'new'
  end
<% if options[:include_activation] %>
  def activate
    self.current_agent = params[:activation_code].blank? ? :false : <%= class_name %>.find_by_activation_code(params[:activation_code])
    if authenticated? && current_agent.respond_to("active?") && !current_agent.active?
      current_agent.activate
      flash[:notice] = "Signup complete!"
    end
    redirect_back_or_default('/')
  end
<% end %>
end
