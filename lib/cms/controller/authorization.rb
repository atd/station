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
    # This sends @somewhere the method do_something_by?(current_agent)
    #
    # If false, it calls access_denied
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
    # This filters match with CMS::Container and CMS::Role
    #
    # To be documented
    # 
    module Authorization
      # Inclusion hook to add CMS::Controller::Authentication
      def self.included(base) #:nodoc:
        base.send :include, CMS::Controller::Authentication unless base.instance_methods.include?('authenticated?')

        base.class_eval do
          alias_method_chain :method_missing, :authorization_filters
        end        
      end
      
      protected

      # Hook for CMS Authorization Filters
      def method_missing_with_authorization_filters(method, *args, &block) #:nodoc:
        if method.to_s =~ /^can__(.*)__(.*)$/
          action = "#{ $1 }_by?"
          object = instance_variable_get("@#{ $2 }")          
          raise Exception.new("Filter #{ method }: can't find variable: @#{ $2 }") unless object
          raise Exception.new("Filter #{ method }: Object #{ object } doesn't respond to action: #{ action }") unless object.respond_to?(action)
          
          access_denied unless object.send(action, current_agent)       
        else
          method_missing_without_authorization_filters(method, *args, &block)
        end
      end     
    end
  end
end
