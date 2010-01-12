require 'rake'

desc 'Default: regenerate rdoc'
task :default => :rdoc

desc 'Regenerate rdoc'
task :rdoc do
  %w( master stable ).each do |branch|
    system "git checkout #{ branch }"
    system 'rake rdoc'
  end

  system "git checkout gh-pages"

  %w( master stable ).each do |branch|
    system "git rm -r rdoc/#{ branch }"
    system "rm -r rdoc/#{ branch }"
    system "mv rdoc-#{ branch } rdoc/#{ branch }"
    system "git add rdoc/#{ branch }"
  end

  system "git commit --amend"
end
