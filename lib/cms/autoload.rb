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

  # Ontology Terms
  # They are mapped to acts_as#{ term } methods 
  TERMS = %w( agent content container )

  TERMS.map(&:pluralize).each do |t|
    mattr_accessor t
    class_variable_set "@@#{ t }", []
  end

  DEFAULT_OPTIONS = {
    :file_pattern => "#{RAILS_ROOT}/app/models/**/*.rb",
    :file_exclusions => ['svn', 'CVS', 'bzr'],
    :requirements => []}
  
  mattr_accessor :options
  @@options = HashWithIndifferentAccess.new(DEFAULT_OPTIONS)      

  @@loaded = false

  # Dispatcher callback to identify CMS classes
  def self.autoload
    return if @@loaded

#    _logger_debug "cms autoload hook invoked"
    
    options[:requirements].each do |requirement|
#      _logger_warn "forcing requirement load of #{requirement}"
      require requirement
    end
  
    Dir[options[:file_pattern]].each do |filename|
      next if filename =~ /#{options[:file_exclusions].join("|")}/
      TERMS.each do |term|
        open filename do |file|
          if file.grep(/acts_as_#{ term }/).any?
            model = File.basename(filename)[0..-4].pluralize.to_sym
#            _logger_warn "adding #{model} to #{ term }"
            class_variable_set "@@#{ term.pluralize }", class_variable_get("@@#{ term.pluralize }") << model
          end
        end
      end
    end
    @@loaded = true
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
