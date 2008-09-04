namespace :cms do
  namespace :db do
    desc 'Create database schema and load Globalize data'
    task :setup => [ "db:schema:load", "globalize:setup", "translate" ]

    desc 'Load current_site translation file'
    task :translate => :environment do
      unless Site.current.locale.blank?
        file = "#{ RAILS_ROOT }/lang/#{ Site.current.locale }.rb"
        raise "File: #{ file } doesn't exist" unless File.exists?(file) 
        require file
      end
    end
  end

#  namespace :users do
#    desc "Sends a mail to users that haven't activated their account. Reminders are sent each config[:freq_user_reminder]. When config[:max_activation_reminder_count] is reached, user is deleted"
#    task :remember_activation => :environment do
#      User.find(:all, :conditions => [ "activated_at is null" ]).each do |user|
#        user.update_attribute :activation_count, user.activation_count + 1
#        if user.activation_count >= config[:max_user_activation_count]
#          user.destroy
#        elsif user.activation_count % config[:freq_user_reminder] == 0
#          UserNotifier.deliver_remember_activation(user)
#        end
#      end
#    end
#  end
end
