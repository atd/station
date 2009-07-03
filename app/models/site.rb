# Site Configuration, global permissions, etc..
#
# == exception_notification plugin integration
# Check <tt>exception_notifications</tt> to receive debuggin emails
#
# You must have the plugin installed
class Site < ActiveRecord::Base
  acts_as_stage
  acts_as_container
  has_logo

  def self.current
    first || create
  end

  def email_with_name
    "#{ name } <#{ email }>"
  end

  #TODO: validate exception_notifications attribute and 
  # exception_notification plugin installation
  after_save do |site|
    begin
      ExceptionNotifier.set_from_site(site)
    rescue NameError
    end
  end
end
