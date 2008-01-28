# Post Controller

class PostController < ApplicationController
  #TODO: authentication
#  before_filter :agent_required,      :except => [ :index, :show ]

  # Posts lists
  before_filter :get_container,       :only   => [ :index ]
  before_filter :can_read_container,  :only   => [ :index ]
  
  # Posts creation
  before_filter :needs_container,     :only   => [ :new, :create ]
  before_filter :can_write_container, :only   => [ :new, :create ]

  # Posts read
  before_filter :get_post,         :except => [ :index, :new, :create ]
  before_filter :can_read_post,    :only   => [ :show, :edit ]
  
  # Post edition, deletion
  before_filter :can_write_post,   :only   => [ :edit, :update, :delete ]

  # A post collection tipically belongs to one container
  # Containers include categories, tags
  # When there is no container, we deliver public contents
  #
  # GET /posts
  # GET /container/1/posts
  # GET /categories/1/posts
  # GET /tags/1/posts

  def index
    # We search for specific contents if the container or the application supports them
    if (@container || CMS).contents.include?(controller_name.to_sym)
      conditions = [ "posts.content_type = ?", controller_name.classify ]
      @content = controller_name.classify.constantize
    end

    if @container
      # All the Posts this Agent can read in this Container
      @collection = @container.posts.find(:all,
                                          :conditions => conditions,
                                          :order => "updated_at DESC").select{ |p|
        p.read_by?(current_agent)
      }

      # Paginate them
      @posts = @collection.paginate(:page => params[:page], :per_page => (@content || Post).per_page)
      @updated = @collection.blank? ? @container.updated_at : @collection.first.updated_at
      @collection_path = "#{ polymorphic_url(@container, :only_path => false) }/#{ controller_name }"
    else
      @title = "#{ controller_name.singularize.titleize.t(controller_name.titleize, 99)}"
      conditions = CMS::Utils.merge_conditions("AND", conditions, [ "public_read = ?", true ]
      @posts = Post.paginate :all,
                             :conditions => conditions,
                             :page =>  params[:page]
                             :order => "updated_at DESC"
      @updated = @posts.blank? ? Time.now : @posts.first.updated_at
      @collection_path = url_for :controller => controller_name
    end

#    @categories.delete_if { |c| c.send(controller_name).count == 0 } if @categories

    respond_to do |format|
      format.html { @page_title = @title }
      format.js
      format.xml { render xml => @posts.to_xml }
      format.atom { render :partial => "posts/feed", :layout => false }
    end
  end

  # GET /contents/:id
  def show
    # Versioned posts, &version=#num
#    if @post.respond_to?("revert_to")
#      @post.revert_to(params[:version]) if params[:version]
#      @post_versions = @post.versions.paginate :per_page => 1,
#                                               :page => (params[:version] || @post.version)
#    end

    @title = @post.title
#    @categories = @content.categories

    respond_to do |format|
      format.html # show.rhtml
      format.atom { 
        headers["Content-type"] = 'application/atom+xml'
        render :partial => "post/entry",
                           :locals => { :post => @post },
                           :layout => false
      }
      format.xml { render :xml => @post.to_xml }

      # Add Content format Mime Type for content with Attachments
      format.send(@post.content.mime_type.to_sym.to_s) {
        send_data @post.content.current_data, :filename => @content.filename,
                                              :type => @content.content_type,
                                              :disposition => @content.class.disposition.to_s
      } if @content.respond_to?("attachment_options")
      
    end
  end

  # GET /context/:context_id/contents/new
  # GET /context/:context_id/contents/new
  def new
    @collection_path = send "#{ @container.class.to_s.underscore }_#{ controller_name }_path", @container
#    params[:category_ids] = ( @category ? [ @category.id.to_s ] : [] )
#    params[:tag_list] = ""
    @post = Post.new
    @post.content = instance_variable_set "@#{controller_name.singularize}", controller_name.classify.constantize.new
    render :template => "posts/new"
  end

  # GET /contents/:id;edit
  def edit
    params[:category_ids] = []
    @content.categories.each do |c|
      params[:category_ids] << c.id.to_s
    end
    params[:tag_list] = @content.tag_list
    render :template => "contents/edit"
  end

  def create
    # FIXME we have to call this because Proc definition doesn't allow
    # call headers parameters, and thus can't get Slug from them
    complete_file_data if params[:format] == "atom" && params[:content] && params[:content][:uploaded_data]
    
    params[:category_ids] ||= @category ? [ @category.id.to_s ] : []
    @content = instance_variable_set "@#{controller_name.singularize}", controller_name.classify.constantize.new(params[:content])
    @content.owner = @space
    @content.author = current_agent

    respond_to do |format|
      format.html {
        if @content.save
          @content.category_ids = params[:category_ids]
          @content.tag_with params[:tag_list]
          flash[:message] = "#{ @content.class.to_s } created".t
          redirect_to send("#{controller_name.singularize}_path", @content )
        else
          @collection_path = send "#{ @context.class.to_s.underscore }_#{ controller_name }_path", @context
          render :template => "contents/new"
        end
      }

      format.atom {
        #TODO categories, tags
        if @content.save
	  headers["Location"] = polymorphic_url(@content, :only_path => false) + '.atom'
	  headers["Content-type"] = 'application/atom+xml'
          render :partial => "contents/entry",
                             :status => :created,
                             :locals => { :content => @content },
                             :layout => false
        else
          render :xml => @content.errors.to_xml, :status => :bad_request
        end
      }
    end
  end

  # PUT /contents/:id
  def update
    # FIXME we have to call this because Proc definition doesn't allow
    # call headers parameters, and thus can't get Slug from them
    complete_file_data if params[:format] == @content.mime_type.to_sym.to_s and params[:content][:uploaded_data]
    params[:content][:owner] = @content.owner
    params[:content][:author] = current_user

    respond_to do |format|
      format.html {
        if @content.update_attributes(params[:content])
          @content.category_ids = params[:category_ids]
          @content.tag_with params[:tag_list]
          flash[:message] = "#{ @content.class.to_s } updated".t
          redirect_to send("#{controller_name.singularize}_path", @content )
        else
          render :template => "contents/edit" 
        end
      }

      format.atom {
        if @content.update_attributes(params[:content])
          #TODO categories, tags
          head :ok
        else
          render :xml => @content.errors.to_xml,
                 :status => :not_acceptable
        end
      }

      # Add Content format Mime Type for content with Attachments
      format.send(@content.mime_type.to_sym.to_s) {
        if @content.update_attributes(params[:content])
          head :ok
        else
          render :xml => @content.errors.to_xml,
                 :status => :not_acceptable
        end
      } if @content.respond_to?("attachment_options")

    end
  end

  # DELETE /content/1
  # DELETE /content/1.xml
  def destroy
    space = @content.owner
    mime_type = @content.mime_type.to_sym.to_s
    @content.destroy

    respond_to do |format|
      format.html { redirect_to send("#{ space.class.to_s.underscore }_#{ controller_name }_path", space) }
      format.atom { head :ok }
      # FIXME: Check AtomPub, RFC 5023
#      format.send(mime_type) { head :ok }
      format.xml { head :ok }
    end
  end

  protected

  def get_container
    @container = check_available_containers || get_category || get_tag
  end

  def check_available_containers
    CMS.containers.each do |container|
      container_fk = container.to_s.singularize.foreign_key

      @container = container.to_class.find params[container_fk] if params[container_fk]
    end

    if @container
      @title = "%s from %s" / [ controller_name.singularize.t(controller_name, 99).titleize, @container.name ]
#      @categories = readable(@space.categories)
    end
  end

  def get_category
#    if params[:category_id]
#      @category = Category.find params[:category_id]
#      @categories = Array(@category)
#      @title = @category.title
#      @space = @category.owner
#    end
#    @category
  end

  def get_tag
#    if params[:tag_id]
#      @tag = Tag.find params[:tag_id]
#      @title = "#{ @tag.name } - #{ controller_name.singularize.t(controller_name, 99).titleize }"
#    end
#    @tag
  end

  def can_read_container
    if @container && !@container.read_by?(current_agent)
      access_denied
    end
  end

  def need_container
    @container = get_container || current_agent
    render(:text => "Forbidden", :status => 403) unless @container.respond_to("has_owner?")
  end

  def can_write_container
    if @container && !@container.write_by?(current_agent)
      access_denied
    end
  end

  def get_post
    @post = Post.find(params[:id])
    @content = @post.content
    @container = @post.container
#    @categories = readable(@space.categories)
  end

  def can_read_post
    access_denied unless @post.read_by?(current_agent)
  end

  def can_write_post
    access_denied unless @post.write_by?(current_agent)
  end
end
