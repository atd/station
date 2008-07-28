#require 'rails_generator'

def update_public_dir(dirname)
  orig = "#{ File.dirname(__FILE__) }/../public/#{ dirname }/cms"
  dest = "#{ RAILS_ROOT }/public/#{ dirname }/cms"
  update_dir(orig, dest)
end

def update_dir(orig, dest)
  Dir.foreach(orig) do |entry|
    next if entry =~ /^\./

    orig_entry = File.join(orig, entry)
    dest_entry = File.join(dest, entry)

    if File.directory?(orig_entry)
      `mkdir -p #{ dest_entry }`
      update_dir(orig_entry, dest_entry)
    else
      if File.exists?(dest_entry)
        if IO.read(orig_entry) == IO.read(dest_entry)
          puts "Identical: #{ dest_entry }"
          next 
        end
        puts "Skipping modified file: #{ dest_entry }"
      else
        puts "Adding: #{ dest_entry }"
        `cp #{ orig_entry } #{ dest_entry }`
      end
    end
  end
end

namespace :cms do
  namespace :update do
    desc "Update CMS javascripts files"
    task :javascripts => :environment do

      require 'rails_generator'
      update_public_dir :javascripts
    end

    desc "Update CMS stylesheets files"
    task :stylesheets => :environment do
      update_public_dir :stylesheets
    end
    
    desc "Update CMS image files"
    task :images => :environment do
      update_public_dir :images
    end
  end

  desc "Update CMS files"
  task :update => [ :"update:javascripts", :"update:stylesheets", :"update:images" ]
end

