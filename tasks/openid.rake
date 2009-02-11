namespace :cms do
  namespace :openid do
    desc "OpenID store Garbage Collector"
    task :gc_ar_store => :environment do
      OpenIdActiveRecordStore.cleanup
    end
  end
end
