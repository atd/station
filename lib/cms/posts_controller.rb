# Post Controller
class CMS::PostsController < ApplicationController
  include CMS::ControllerMethods
  include CMS::Authentication

  before_filter :authentication_required, :except => [ :index, :show ]

  # Posts list filters
  before_filter :get_container,       :only   => [ :index ]
  before_filter :can_read_container,  :only   => [ :index ]
  
  # Posts creation filters
  before_filter :needs_container,     :only   => [ :create ]
  before_filter :can_write_container, :only   => [ :create ]

  # Posts read filters
  before_filter :get_post,         :except => [ :index, :create ]
  before_filter :can_read_post,    :only   => [ :show, :edit ]
  
  # Post edition, deletion filters
  before_filter :can_write_post,   :only   => [ :edit, :edit_media, :update, :update_data, :delete ]

  # A post collection tipically belongs to one container
  # When there is no container, public contents posts are listed
  #
  # GET /posts
  # GET /:container_type/:container_id/posts
  # GET /tags/1/posts
  def index
    if @container
      @title ||= "#{ @container.name } - Posts"
      # All the Posts this Agent can read in this Container
      @collection = @container.posts.find(:all,
                                          :order => "updated_at DESC").select{ |p|
        p.read_by?(current_agent)
      }

      # Paginate them
      @posts = @collection.paginate(:page => params[:page], :per_page => CMS::Post.per_page)
      @updated = @collection.blank? ? @container.updated_at : @collection.first.updated_at
      @collection_path = container_posts_url(:container_type => @container.class.to_s.tableize,
                                             :container_id => @container.id,
                                             :only_path => false)
    else
      @title ||= "Public Posts"
      conditions = CMS::Utils.merge_conditions("AND", conditions, [ "public_read = ?", true ])
      @posts = CMS::Post.paginate :all,
                                  :conditions => [ "public_read = ?", true ],
                                  :page =>  params[:page],
                                  :order => "updated_at DESC"
      @updated = @posts.blank? ? Time.now : @posts.first.updated_at
      @collection_path = url_for :controller => controller_name
    end

    respond_to do |format|
      format.html
      format.xml { render xml => @posts.to_xml }
      format.atom { render :partial => "posts/feed", :layout => false }
    end
  end

  # GET /posts/:id
  def show
    @title ||= @post.title

    respond_to do |format|
      format.html
      format.xml { render :xml => @post.to_xml }
      format.atom { 
        headers["Content-type"] = 'application/atom+xml'
        render :partial => "post/entry",
                           :locals => { :post => @post },
                           :layout => false
      }

      # Add Content format Mime Type for content with Attachments
      # TODO ??
#      format.send(@post.content.mime_type.to_sym.to_s) {
#        send_data @post.content.current_data, :filename => @content.filename,
#                                              :type => @content.content_type,
#                                              :disposition => @content.class.disposition.to_s
#      } if @content.respond_to?("attachment_options")
      
    end
  end

  # GET /posts/:id/edit
  def edit
    render :template => "posts/edit"
  end

  # GET /posts/:id/edit_media
  def edit_media
    render :template => "posts/edit_media"
  end

  # PUT /posts/:id
  def update
    # If the Content of this Post hasn't attachment, update it here
    # If it has, update via update_media
    unless @post.content.has_attachment
      @content = @post.content.class.create params[:content]
    end

    # Avoid change container through params
    params[:post][:container] = @post.container
    params[:post][:agent] = current_agent
    params[:post][:content] = @content

    respond_to do |format|
      format.html {
        if !@content.new_record? && @post.update_attributes(params[:post])
          flash[:notice] = "#{ @content.class.to_s } updated"
          redirect_to post_url @post
        else
          render :template => "posts/edit" 
        end
      }

      format.atom {
        if !@content.new_record? && @post.update_attributes(params[:post])
          head :ok
        else
          render :xml => [ @content.errors + @post.errors ].to_xml,
                 :status => :not_acceptable
        end
      }
    end
  end

  # Update Media Data
  # PUT /posts/:id/update_media
  def update_media
    return unless @post.content.has_attachment

    @content = @post.content.class.create(params[:content])

    respond_to do |format|
      format.html {
        if !@content.new_record?
          @post.update_attribute :content, @content
          flash[:notice] = "#{ @content.class.to_s } updated"
          redirect_to post_url(@post)
        else
          render :template => "posts/edit_data"
        end
      }

      format.atom {
        if !@content.new_record?
          @post.update_attribute :content, @content
          head :ok
        else
          render :xml => @content.errors.to_xml,
                 :status => :not_acceptable
        end
      } 
    end
  end

  # DELETE /posts/1
  def destroy
    @post.destroy

    respond_to do |format|
      format.html { redirect_to container_contents_url }
      format.atom { head :ok }
      # FIXME: Check AtomPub, RFC 5023
#      format.send(mime_type) { head :ok }
      format.xml { head :ok }
    end
  end

  protected

    def get_post #:nodoc:
      @post = CMS::Post.find(params[:id])
      @content = @post.content
      @container = @post.container
    end

    def can_read_post #:nodoc:
      access_denied unless @post.read_by?(current_agent)
    end

    def can_write_post #:nodoc:
      access_denied unless @post.write_by?(current_agent)
    end
end
