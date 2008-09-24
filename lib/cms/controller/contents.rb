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
      # When there is no Container requested, just deliver all Contents
      #
      # If a Container is requested, each Content has an Entry associated with it.
      # See Content#entry
      #
      #   GET /contents
      #   GET /:container_type/:container_id/contents
      def index(&block)
        if current_container
          @title ||= "#{ self.resource_class.translated_named_collection } - #{ current_container.name }"
          @agents = current_container.actors
        else
          @title ||= self.resource_class.translated_named_collection
          @agents = CMS.agent_classes.map(&:all).flatten.sort{ |a, b| a.name <=> b.name }
        end

        # AtomPub feeds are ordered by Entry#updated_at
        if request.format == Mime::ATOM
          params[:order], params[:direction] = "entries.updated_at", "DESC"
        end

        @contents = self.resource_class.in_container(current_container).column_sort(params[:order], params[:direction]).paginate(:page => params[:page])
        instance_variable_set "@#{ self.resource_class.to_s.tableize }", @contents

        @updated = @contents.any? ? @contents.first.entry.updated_at : Time.now.utc

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
      #
      #   GET /contents/:id
      #   GET /:container_type/:container_id/contents/:id
      #
      # In the last case, +@content.entry+ is entry relative to the Container. See Content#entry
      def show
        # Image thumbnails. &thumbnail=thumb
        @content = @content.thumbnails.find_by_thumbnail(params[:thumbnail]) if params[:thumbnail] && @content.respond_to?(:thumbnails)
        instance_variable_set "@#{ self.resource_class.to_s.underscore }", @content

        @title ||= @content.entry.title if @content.entry

        @containers ||= current_container ? 
                        Array(current_container) : 
                        @content.content_entries.map(&:container).uniq
        @agents ||= @content.content_entries.map(&:agent).uniq

        respond_to do |format|
          format.html
          format.xml { render :xml => @content.to_xml }
          format.atom
    
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
      #   GET /:container_type/:container_id/contents/new
      #   GET /contents/new
      def new
        @content = self.resource_class.new
        @content.entry = Entry.new(:content => @content)
        instance_variable_set("@#{ self.resource_class.to_s.underscore }", @content)
        @title ||= "New #{ self.resource_class.to_s.humanize }".t
      end

      # Render form for updating Content
      #
      #   GET /contents/:id/edit
      #   GET /:container_type/:container_id/contents/:id/edit
      def edit
        @title ||= "Editing #{ self.resource_class.to_s.humanize }".t
        params[:category_ids] ||= @content.entry.category_ids
      end
   
      # Create new Content
      #
      #   POST /:container_type/:container_id/contents
      #   POST /contents
      def create
        # Fill params when POSTing raw data
        set_params_from_raw_post
    
        # TODO: we should look for an existing content instead of creating a new one
        # every time a Content is posted.
        # Idea: Should use SHA1 on one or some relevant Content field(s) 
        # and find_or_create_by_sha1
        @content = instance_variable_set "@#{controller_name.singularize}", self.resource_class.new(params[self.resource_class.to_s.underscore.to_sym])
    
        params[:entry] ||= {}
        params[:entry][:agent]     = current_agent
        params[:entry][:container] = current_container
        params[:entry][:content]   = @content
        @content.entry = Entry.new(params[:entry])

        respond_to do |format| 
          format.html {
            if @content.save
              @content.entry.category_ids = params[:category_ids]
              flash[:valid] = "#{ @content.class.to_s.humanize } created".t
              redirect_to [ current_container.to_ppath, @content ]
            else
              @title ||= "New #{ controller_name.singularize.humanize }".t
              render :action => 'new'
            end
          }
    
          format.atom {
            if @content.save
              headers["Location"] = formatted_polymorphic_url([ current_container.to_ppath, @content, :atom ])
              render :action => 'show',
                     :status => :created

            else
              render :xml => @content.errors.to_xml, :status => :bad_request
            end
          }
        end
      end

      # Update Content
      #
      #   PUT /:container_type/:container_id/contents/:id
      #   PUT /contents/:id
      def update
        # Fill params when POSTing raw data
        set_params_from_raw_post
    
        # TODO?: we should look for an existing content instead of creating a new one
        # every time a Content is posted.
        # Idea: Should use SHA1 on one or some relevant Content field(s) 
        # and find_or_create_by_sha1
        #
        # FIXME: what if there are several entries?
        if @content.entry
          params[:entry] ||= {}
          params[:entry][:agent]     = current_agent
          params[:entry][:container] = current_container || @content.entry.container
          params[:entry][:content]   = @content

          @content.entry.attributes = params[:entry]
        end

        respond_to do |format| 
          format.html {
            if @content.update_attributes(params[self.resource_class.to_s.underscore.to_sym])
              @content.entry.category_ids = params[:category_ids] if @content.entry
              flash[:valid] = "#{ @content.class.to_s.humanize } updated".t
              redirect_to [ current_container.to_ppath, @content ].compact
            else
              @title ||= "Editing #{ controller_name.singularize.humanize }".t
              render :action => 'edit'
            end
          }
    
          format.atom {
            if @content.update_attributes(params[self.resource_class.to_s.underscore.to_sym])
              head :ok
            else
              render :xml => @content.errors.to_xml, :status => :not_acceptable
            end
          }

          format.send(@content.format) {
            if @content.update_attributes(params[self.resource_class.to_s.underscore.to_sym])
              head :ok
            else
              render :xml => @content.errors.to_xml, :status => :not_acceptable
            end
          }
        end
      end

      # Delete this Content
      #
      #   DELETE /contents/:id
      #   DELETE /:container_type/:container_id/contents/:id
      def destroy
        @content.destroy

        respond_to do |format|
          format.html { redirect_to polymorphic_path([ current_container.to_ppath, self.resource_class.new ].compact) }
          format.atom { head :ok }
          # FIXME: Check AtomPub, RFC 5023
    #      format.send(mime_type) { head :ok }
          format.xml { head :ok }
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
