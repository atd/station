class <%= class_name %>Observer < ActiveRecord::Observer
  def after_create(<%= file_name %>)
    <%= class_name %>Mailer.deliver_signup_notification(<%= file_name %>)
  end

  def after_save(<%= file_name %>)
  <% if options[:include_activation] -%>
    <%= class_name %>Mailer.deliver_activation(<%= file_name %>) if <%= file_name %>.pending?
    <%= class_name %>Mailer.deliver_forgot_password(<%= file_name %>) if <%= file_name %>.recently_forgot_password?
    <%= class_name %>Mailer.deliver_reset_password(<%= file_name %>) if <%= file_name %>.recently_reset_password?
  <% end -%>
  end
end
