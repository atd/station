# Adapted from HasManyPolymorphs plugin
# Copyright 2007, 2008 Cloudburst, LLC. Licensed under the AFL 3.

require 'initializer' unless defined? ::Rails::Initializer 
require 'dispatcher' unless defined? ::ActionController::Dispatcher

module CMS

=begin rdoc    
Searches for models that use <tt>acts_as_content</tt> and includes them in CMS.contents

Note that you can override DEFAULT_OPTIONS via Rails::Configuration#cms_options. For example, if you need an application extension to be required before cms loads your models, add an <tt>after_initialize</tt> block in <tt>config/environment.rb</tt> that appends to the <tt>'requirements'</tt> key:
  Rails::Initializer.run do |config|     
    # your other configuration here
    
    config.after_initialize do
      config.cms_options['requirements'] << 'lib/my_extension'
    end    
  end
  
=end

  DEFAULT_OPTIONS = {
    :file_patterns => [ RAILS_ROOT, File.dirname(__FILE__).gsub("/lib/cms", '') ].map{ |f| f + '/app/models/**/*.rb' },
    :file_exclusions => ['svn', 'CVS', 'bzr'],
    :requirements => []}
  
  mattr_accessor :options
  @@options = HashWithIndifferentAccess.new(DEFAULT_OPTIONS)      

  @@loaded = false

  class << self
  # Dispatcher callback to identify CMS classes
    def autoload
      return if @@loaded

#    _logger_debug "cms autoload hook invoked"
    
      options[:requirements].each do |requirement|
#      _logger_warn "forcing requirement load of #{requirement}"
        require requirement
      end
  
      for file_pattern in options[:file_patterns]
        Dir[file_pattern].each do |filename|
          next if filename =~ /#{options[:file_exclusions].join("|")}/
          open filename do |file|
            begin
              require_dependency(filename) if file.grep(/acts_as_(#{ CMS::ActiveRecord::ActsAs::LIST.join('|') })/).any?
            rescue Exception => e
              #FIXME: logger ?
              puts "CMSplugin autoload: Couldn't load file #{ filename }: #{ e }"
            end
          end
        end
      end
      @@loaded = true
    end  
  end
end

module Rails #:nodoc: all
  class Initializer
    # Make sure it gets loaded in the console, tests, and migrations
    def after_initialize_with_cms_autoload 
      after_initialize_without_cms_autoload
      CMS.autoload
    end
    alias_method_chain :after_initialize, :cms_autoload 
  end
end

Dispatcher.to_prepare(:cms_autoload) do
  # Make sure it gets loaded in the app
  CMS.autoload
end
