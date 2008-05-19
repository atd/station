module CMS
  module Controller
    # Authorization module provides your Controller with filters to control
    # the actions of Agents
    #
    # This module uses Agent identification support from CMS::Controller::Authentication
    #
    # == Filters
    # Authorization filters can defined in the following way:
    #   before_filter :can__do_something__somewhere
    # This calls @somewhere.do_something_by?(current_agent)
    #
    # If true, the filter passes. If false, it calls 
    # CMS::Controller::Authentication#access_denied
    #
    # Let's see an example:
    #
    #   class Foo
    #     def read_by?(agent)
    #       # true or false
    #     end
    #   end
    #
    #   class FooController < ApplicationController
    #     include CMS::Controller::Authorization
    #
    #     before_filter :get_foo
    #     before_filter :can__read__foo, :only => [ :show ]
    #   end
    #
    # == Containers and Roles
    # These filters match with CMS::Container and CMS::Role
    #
    # To be documented
    # 
    module Authorization
      # Inclusion hook to add CMS::Controller::Authentication
      def self.included(base) #:nodoc:
        base.send :include, CMS::Controller::Authentication unless base.instance_methods.include?('authenticated?')

        authorization_filters_proc = lambda do
          alias_method :method_missing_without_authorization_methods, :method_missing
          alias_method :method_missing_without_authorization_filters, :method_missing_with_authorization_methods
          alias_method :method_missing, :method_missing_with_authorization_filters
        end

        base.class_eval &authorization_filters_proc

	      authorization_methods_proc = lambda do
          alias_method_chain :method_missing, :authorization_methods
       	end
        
        base.helper_method :method_missing_with_authorization_methods
       	base.master_helper_module.module_eval &authorization_methods_proc
      end
      
      # Set HTTP Forbidden (403) response for actions not authorized
      def not_authorized
        respond_to do |format|
          format.html do
            render :file => "#{RAILS_ROOT}/public/403.html", 
                   :status => 403
          end
          
          for mime in CMS.mime_types
            format.send mime.to_sym do
              render :text => 'Forbidden',
                     :status => 403
            end
          end
        end
      end
      
      protected

      # Hook for CMS Authorization Filters
      def method_missing_with_authorization_methods(method, *args, &block) #:nodoc:
        if method.to_s =~ /^can__(.*)__(.*)$/
          action = "#{ $1 }_by?"
          object = instance_variable_get("@#{ $2 }")          
          raise Exception.new("Filter #{ method }: can't find variable: @#{ $2 }") unless object
          raise Exception.new("Filter #{ method }: Object #{ object } doesn't respond to action: #{ action }") unless object.respond_to?(action)
          
          object.send(action, current_agent)       
        else
          method_missing_without_authorization_methods(method, *args, &block)
        end
      end

      def method_missing_with_authorization_filters(method, *args, &block) #:nodoc:
        if method.to_s =~ /^(can__.*)__filter$/
          not_authorized unless send($1)       
        else
          method_missing_without_authorization_filters(method, *args, &block)
        end
      end
      
    end
  end
end
