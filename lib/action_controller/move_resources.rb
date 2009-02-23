module ActionController #:nodoc:
  # Controller methods for Resources
  #
  module MoveResources
    class << self
      def included(base) #:nodoc:
        base.send :include, ActionController::Move unless base.ancestors.include?(ActionController::Move)
      end
    end

    # GET /resources
    # GET /resources.xml
    def index
      # AtomPub feeds are ordered by Entry#updated_at
      if request.format == Mime::ATOM
        params[:order], params[:direction] = "updated_at", "DESC"
      end

      @resources = model_class.column_sort(params[:order], params[:direction]).paginate(:page => params[:page])
      instance_variable_set "@#{ model_class.to_s.tableize }", @resources
      @title ||= t(model_class.to_s.underscore, :count => :other)

      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @resources }
        format.atom
      end
    end

    # GET /resources/1
    # GET /resources/1.xml
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
        } unless resource.class.resource_options[:has_media].nil?

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

    # GET /resources/new
    # GET /resources/new.xml
    def new
      @resource = model_class.new
      instance_variable_set "@#{ model_class.to_s.underscore }", @resource
      @title ||= t(:new, :scope => model_class.to_s.underscore)

      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => @resource }
      end
    end

    # GET /resources/1/edit
    def edit
      resource
      @title ||= t(:editing, :scope => model_class.to_s.underscore)
    end

    # POST /resources
    # POST /resources.xml
    def create
      # Fill params when POSTing raw data
      set_params_from_raw_post

      @resource = model_class.new(params[model_class.to_s.underscore.to_sym])
      instance_variable_set "@#{ model_class.to_s.underscore }", @resource

      respond_to do |format|
        if @resource.save
          flash[:valid] = t(:created, :scope => @resource.class.to_s.underscore)
          format.html { redirect_to(@resource) }
          format.xml  { render :xml => @resource, :status => :created, :location => @resource }
          format.atom {
            headers["Location"] = polymorphic_url(@resource)
            render :action => 'show',
                   :status => :created
          }
        else
          format.html { 
            render :action => "new"
            @title ||= t(:new, :scope => model_class.to_s.underscore)
          }
          format.xml  { render :xml => @resource.errors, :status => :unprocessable_entity }
          format.atom { render :xml => @resource.errors.to_xml, :status => :bad_request }
        end
      end
    end

    # PUT /resources/1
    # PUT /resources/1.xml
    def update
      # Fill params when POSTing raw data
      set_params_from_raw_post

      respond_to do |format| 
        xml_formats = [ :atom, :all ]
        xml_formats << resource.format unless resource.format == :html

        format.any(*xml_formats) {
          if resource.update_attributes(params[model_class.to_s.underscore.to_sym])
            head :ok
          else
            render :xml => @resource.errors.to_xml, :status => :not_acceptable
          end
        }

        format.html {
          if resource.update_attributes(params[model_class.to_s.underscore.to_sym])
            flash[:valid] = t(:updated, :scope => @resource.class.to_s.underscore)
            redirect_to @resource
          else
            @title ||= t(:editing, :scope => model_class.to_s.underscore)
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
        format.html { redirect_to(polymorphic_path(model_class.new)) }
        format.xml  { head :ok }
        format.atom { head :ok }
      end
    end

    protected

    def resource
      @resource ||= instance_variable_set("@#{ model_class.to_s.underscore }", 
                                          model_class.find(params[:id]))
    end
  end
end
