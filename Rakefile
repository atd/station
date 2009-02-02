require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test the cms plugin.'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end

desc 'Generate documentation for the cms plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'CMSplugin'
  rdoc.template = 'doc/template/horo.rb'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb', 'app/**/*.rb')
end

desc 'Publish documentation in RubyForge site'
task :publish_rdoc => [ :rdoc ] do
  `scp -r rdoc/* atd@rubyforge.org:/var/www/gforge-projects/cmsplugin`
end
