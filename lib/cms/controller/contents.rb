module CMS
  module Controller
    # Controller methods and default filters for Agents Controllers
    module Contents
      def self.included(base) #:nodoc:
        base.send :include, CMS::Controller::Base unless base.ancestors.include?(CMS::Controller::Base)
        base.send :include, CMS::Controller::Authorization unless base.ancestors.include?(CMS::Controller::Authorization)
      end

      # List Contents of this type posted to a Container
      #
      # When there is no Container requested, just deliver public Contents
      #
      #   GET /:container_type/:container_id/contents
      #   GET /contents
      def index(&block)
        if current_container
          @title ||= "#{ self.resource_class.translated_named_collection } - #{ current_container.name }"
          @agents = current_container.actors
        else
          @title ||= self.resource_class.translated_named_collection
          @agents = CMS.agent_classes.map(&:all).flatten.sort{ |a, b| a.name <=> b.name }
        end

        @contents = self.resource_class.in_container(current_container).column_sort(params[:order], params[:direction]).paginate(:page => params[:page])
        instance_variable_set "@#{ self.resource_class.to_s.tableize }", @contents

        @updated = @contents.any? ? @contents.first.entry_updated_at : Time.now.utc

        @containers = current_user.stages
    
        if block
          yield
        else
          respond_to do |format|
            format.html
            format.js
            format.xml { render :xml => @contents.to_xml }
            format.atom
          end
        end
      end
    
      # Show this Content
      #   GET /:content_type/:id
      def show
        # Image thumbnails. &thumbnail=thumb
        @content = @content.thumbnails.find_by_thumbnail(params[:thumbnail]) if params[:thumbnail] && @content.respond_to?(:thumbnails)
        instance_variable_set "@#{ self.resource_class.to_s.underscore }", @content

        respond_to do |format|
          format.html
          format.xml { render :xml => @content.to_xml }
    
          # Add Content format Mime Type for content with Attachments
          format.send(@content.mime_type.to_sym.to_s) {
            send_data @content.current_data, :filename => @content.filename,
                                             :type => @content.content_type,
                                             :disposition => @content.class.content_options[:disposition].to_s
          } if @content.mime_type
    
          format.all {
            headers["Content-type"] = @content.mime_type.to_s
            send_data @content.current_data, :filename => @content.filename,
                                             :type => @content.content_type,
                                             :disposition => @content.class.content_options[:disposition].to_s
          } if @content.mime_type
        end
      end
    
      # Render form for posting new Content
      #
      # When no container is specified, tries posting to Agent's
      #   GET /:container_type/:container_id/contents/new
      #   GET /contents/new
      def new
        @entry = Entry.new
        @entry.content = @content = self.resource_class.new
        instance_variable_set("@#{ self.resource_class.to_s.underscore }", @content)
        @title ||= "New #{ self.resource_class.to_s.humanize }".t
      end
    
      # Create new Content
      #
      #   POST /:container_type/:container_id/contents
      #   POST /contents
      def create
        # Fill params when POSTing raw data
        set_params_from_raw_post
    
        set_params_title_and_description(self.resource_class)
    
        # FIXME: we should look for an existing content instead of creating a new one
        # every time a Content is posted.
        # Idea: Should use SHA1 on one or some relevant Content field(s) 
        # and find_or_create_by_sha1
        @content = instance_variable_set "@#{controller_name.singularize}", self.resource_class.create(params[:content])
    
        @entry = Entry.new(params[:entry].merge({ :agent => current_agent,
                                                  :container => @container,
                                                  :content => @content }))
    
        respond_to do |format| 
          format.html {
            if !@content.new_record? && @entry.save
              @entry.category_ids = params[:category_ids]
              flash[:valid] = "#{ @content.class.to_s.humanize } created".t
              redirect_to @entry
            else
              @content.destroy unless @content.new_record?
              @entry.content = @content = instance_variable_set("@#{controller_name.singularize}", controller_name.classify.constantize.new)
              @title ||= "New #{ controller_name.singularize.humanize }".t
              render :action => 'new'
            end
          }
    
          format.atom {
            if !@content.new_record? && @entry.save
    	  headers["Location"] = formatted_entry_url(@entry, :atom)
    	  headers["Content-type"] = 'application/atom+xml'
              render :partial => "entries/entry",
                                 :status => :created,
                                 :locals => { :entry => @entry,
                                              :content => @content },
                                 :layout => false
            else
              if @content.new_record?
                render :xml => @content.errors.to_xml, :status => :bad_request
              else
                @content.destroy unless @content.new_record?
                render :xml => @entry.errors.to_xml, :status => :bad_request
              end
            end
          }
        end
      end
    
      protected

      # Render Bad Request unless the controller name relates to a class that acts_as_content. 
      # If current_container exists, check its valid contents
      def controller_name_is_valid_content
        unless (current_container && current_container.container_options[:contents] || CMS.contents).include?(self.resource_class.collection)
          render :text => "Doesn't support this Content type", :status => 400
        end
      end
     
      # Get current content based in the controller name. 
      #
      # Sets +@content+ and an content name specific instance variable
      #
      # Example:
      #   class ArticlesController < ActiveRecord::Base
      #     include CMS::Controller::Contents
      #
      #     before_filter :get_content #=> @article = @content = Article.find(params[:id])
      #   end
      #
      # If current_container exists, +@content+ has its entry defined. 
      # This funcion uses CMS::Content#in_container named scope
      #
        def get_content
          @content = self.resource_class.in_container(current_container).find params[:id]
          instance_variable_set "@#{ self.resource_class.to_s.underscore }", @content
        end
    end
  end
end
