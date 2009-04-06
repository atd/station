module ActionController #:nodoc:
  # Controller methods for Resources
  #
  module MoveResources
    class << self
      def included(base) #:nodoc:
        base.send :include, ActionController::Move unless base.ancestors.include?(ActionController::Move)
        base.send :include, ActionController::Authorization unless base.ancestors.include?(ActionController::Authorization)
      end
    end

    # List Resources
    #
    # When the Resource is a Content, uses in_container named_scope
    # When it's a Sortable, uses column_sort named_scope
    #
    # It also paginates using great Mislav will_paginate plugin
    #
    #   GET /resources
    #   GET /resources.xml
    #   GET /resources.atom
    #
    #   GET /:container_type/:container_id/contents
    #   GET /:container_type/:container_id/contents.xml
    #   GET /:container_type/:container_id/contents.atom
    def index(&block)
      # AtomPub feeds are ordered by updated_at
      # TODO: move this to ActionController::Base#params_parser
      if request.format == Mime::ATOM
        params[:order], params[:direction] = "updated_at", "DESC"
      end

      @resources = model_class.parents.in_container(container).column_sort(params[:order], params[:direction]).paginate(:page => params[:page])
      instance_variable_set "@#{ model_class.to_s.tableize }", @resources
      @contents = @resources if model_class.acts_as?(:content)

      if block
        yield
      else
        respond_to do |format|
          format.html # index.html.erb
          format.js
          format.xml  { render :xml => @resources }
          format.atom
        end
      end
    end

    # Show this Content
    #
    #   GET /resources/1
    #   GET /resources/1.xml
    def show
      if params[:thumbnail] && resource.respond_to?(:thumbnails)
        @resource = resource.thumbnails.find_by_thumbnail(params[:thumbnail]) 
      end

      instance_variable_set "@#{ model_class.to_s.underscore }", resource
      @title = resource.title if resource.respond_to?(:title)

      respond_to do |format|
        format.all {
          send_data resource.current_data, :filename => resource.filename,
                                           :type => resource.content_type,
                                           :disposition => resource.class.resource_options[:disposition].to_s
        } if resource.class.resource_options[:has_media]

        format.html # show.html.erb
        format.xml  { render :xml => @resource }
        format.atom
  
        # Add Resource format Mime Type for resource with Attachments
        format.send(resource.mime_type.to_sym.to_s) {
          send_data resource.current_data, :filename => resource.filename,
                                           :type => resource.content_type,
                                           :disposition => resource.class.resource_options[:disposition].to_s
        } if resource.mime_type

      end
    end

    # Render form for posting new Resource
    #
    #   GET /resources/new
    #   GET /resources/new.xml
    #   GET /:container_type/:container_id/contents/new
    def new
      @resource = model_class.new
      instance_variable_set "@#{ model_class.to_s.underscore }", @resource
      @content = @resource if model_class.acts_as?(:content)

      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => @resource }
      end
    end

    # GET /resources/1/edit
    def edit
      resource
    end

    # Create new Resource
    #
    #   POST /resources
    #   POST /resources.xml
    #   POST /:container_type/:container_id/contents
    def create
      # Fill params when POSTing raw data
      set_params_from_raw_post

      resource_params = params[model_class.to_s.underscore.to_sym]
      resource_class =
        model_class.resource_options[:delegate_content_types] &&
        resource_params[:media] && resource_params[:media].present? &&
        ActiveRecord::Resource.class_supporting(resource_params[:media].content_type) ||
        model_class

      @resource = resource_class.new(resource_params)
      instance_variable_set "@#{ model_class.to_s.underscore }", @resource
      @content = @resource if @resource.class.acts_as?(:content)

      @resource.author = current_agent if @resource.respond_to?(:author=)
      @resource.container = container  if @resource.respond_to?(:container=)

      respond_to do |format|
        if @resource.save
          flash[:success] = t(:created, :scope => @resource.class.to_s.underscore)
          format.html { 
            redirect_to resource_or_content_path_args
          }
          format.xml  { 
            render :xml      => @resource, 
                   :status   => :created, 
                   :location => @resource 
          }
          format.atom {
            render :action => 'show',
                   :status => :created,
                   :location => formatted_polymorphic_url(resource_or_content_path_args << :atom)
          }
        else
          format.html { 
            render :action => "new"
          }
          format.xml  { render :xml => @resource.errors, :status => :unprocessable_entity }
          format.atom { render :xml => @resource.errors.to_xml, :status => :bad_request }
        end
      end
    end

    # Update Resource
    #
    # PUT /resources/1
    # PUT /resources/1.xml
    def update
      # Fill params when POSTing raw data
      set_params_from_raw_post

      resource

      respond_to do |format| 
        xml_formats = [ :atom, :all ]
        xml_formats << resource.format if resource.format

        format.any(*xml_formats) {
          if resource.update_attributes(params[model_class.to_s.underscore.to_sym])
            head :ok
          else
            render :xml => @resource.errors.to_xml, :status => :not_acceptable
          end
        }

        format.html {
          if resource.update_attributes(params[model_class.to_s.underscore.to_sym])
            flash[:success] = t(:updated, :scope => @resource.class.to_s.underscore)
            redirect_to resource_or_content_path_args
          else
            render :action => 'edit'
          end
        }
      end
    end

    # DELETE /resources/1
    # DELETE /resources/1.xml
    def destroy
      resource.destroy

      respond_to do |format|
        format.html { redirect_to(polymorphic_path(model_class.acts_as?(:content) ? 
                                                   [ container, model_class.new ] :
                                                   model_class.new))
        }
        format.xml  { head :ok }
        format.atom { head :ok }
      end
    end

    protected

    def resource
      @resource ||= instance_variable_set("@#{ model_class.to_s.underscore }", 
                                          model_class.in_container(container).find_with_param(params[:id]))

      @content  ||= @resource if @resource.class.acts_as?(:content)
      @resource
    end

    def resource_or_content_path_args
      resource.class.acts_as?(:content) ? [ container, resource ] : Array(resource)
    end
  end
end
