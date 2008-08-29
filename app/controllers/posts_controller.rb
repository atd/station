# Controller methods and default filters for Posts Controllers
class PostsController < ApplicationController
  include CMS::Controller::Base unless self.ancestors.include? CMS::Controller::Base
  include CMS::Controller::Authorization unless self.ancestors.include? CMS::Controller::Authorization

  before_filter :get_post, :only => [ :show, :edit, :update, :destroy, :details ]

  # List Posts belonging to Container
  #
  # List all posts when no Container is specified
  #
  #   GET /:container_type/:container_id/posts
  #   GET /posts
  def index
    if current_container
      @title ||= "#{ current_container.name } - #{ 'Post'.t('Posts', 99) }"
      
      @posts = current_container.container_posts.column_sort(params[:order], params[:direction]).paginate(:page => params[:page], :per_page => Post.per_page)

      @updated = @posts.blank? ? current_container.updated_at : @posts.first.updated_at
    else
      @title ||= 'Post'.t('Posts', 99)
      @posts = Post.column_sort(params[:order], params[:direction]).paginate(:page =>  params[:page])
      @updated = @posts.blank? ? Site.current.created_at : @posts.first.updated_at
    end

    @agents = CMS.agent_classes.map(&:all).flatten.sort{ |a, b| a.name <=> b.name }
    container_classes = CMS.container_classes - ( CMS.agent_classes + [ Site, Post ] )
    @containers = container_classes.map(&:all).flatten.uniq.sort{ |a, b| a.name <=> b.name }

    respond_to do |format|
      format.html
      format.atom
      format.xml { render :xml => @posts.to_xml }
    end
  end

  # Show this Post
  #   GET /posts/:id
  def show
    @title ||= @post.title

    @containers = Array(@post.container)
    @agents = @post.container.actors

    respond_to do |format|
      format.html
      format.xml { render :xml => @post.to_xml(:include => [ :content ]) }
      format.atom { 
        headers["Content-type"] = 'application/atom+xml'
        render :partial => "posts/entry",
                           :locals => { :post => @post },
                           :layout => false
      }
      format.json { render :json => @post.to_json(:include => :content) }
    end
  end

  # Renders form for editing this Post metadata
  #   GET /posts/:id/edit
  def edit
    get_params_title_and_description(@post)
    params[:category_ids] = @post.category_ids

    render :template => "posts/edit"
  end

  # Update this Post metadata
  #   PUT /posts/:id
  def update
    set_params_title_and_description(@post.content)

    # If the Content of this Post hasn't attachment, update it here
    # If it has, update via media
    # 
    # TODO: find old content when only post params are updated
    # TODO: Update in AtomPub?
#        unless request.format == :atom
#        @content = @post.content.class.create params[:content]
#        end

    # Avoid the user changes container through params
    params[:post][:container] = @post.container
    params[:post][:agent]     = current_agent

    respond_to do |format|
      format.html {
        if @post.content.update_attributes(params[:content]) && 
          @post.update_attributes(params[:post])
          @post.category_ids = params[:category_ids]
          flash[:valid] = "#{ @content.class.to_s.humanize } updated".t
          redirect_to @post
        else
          render :template => "posts/edit" 
        end
      }

      format.atom {
        if @post.content.update_attributes(params[:content]) && @post.update_attributes(params[:post])
          head :ok
        else
          render :xml => [ @content.errors + @post.errors ].to_xml,
                 :status => :not_acceptable
        end
      }
    end
  end

  # Manage Post media (if Post has media)
  # Retreive media
  #   GET /posts/:id/media 
  # Update media
  #   PUT /posts/:id/media 
  def media
    if request.get?
      # Render media file
      @content = @post.content
      
      # Get thumbnail if content supports it and asking for it
      @content = @content.thumbnails.find_by_thumbnail(params[:thumbnail]) if 
        params[:thumbnail] && @content.respond_to?(:thumbnails)

      headers["Content-type"] = @content.mime_type.to_s
      send_data @content.current_data, :filename => @content.filename,
                                       :type => @content.content_type,
                                       :disposition => @content.class.content_options[:disposition].to_s
    elsif request.put?
      # Have to set write post filter here
      # because doesn't apply to GET
      unless @post.update_by? current_agent
        access_denied
        return
      end

      # Set params when putting raw data
      set_params_from_raw_post

      respond_to do |format|
        format.html {
          if @post.content.update_attributes(params[:content])
            flash[:valid] = "#{ @content.class.to_s.humanize } updated".t
            redirect_to @post
          else
            render :template => "posts/edit_media"
          end
        }

        format.atom {
          if @post.content.update_attributes(params[:content])
            head :ok
          else
            render :xml => @post.content.errors.to_xml,
                   :status => :not_acceptable
          end
        } 
      end
    else
      bad_request
    end
  end

  # Renders form for editing this Post's media
  #   GET /posts/:id/edit_media
  def edit_media
    render :template => "posts/edit_media"
  end

  # Delete this Post
  #   DELETE /posts/:id
  def destroy
    @post.destroy

    respond_to do |format|
      format.html { redirect_to polymorphic_path(@container) }
      format.atom { head :ok }
      # FIXME: Check AtomPub, RFC 5023
#      format.send(mime_type) { head :ok }
      format.xml { head :ok }
    end
  end

  protected

    # Find Post using params[:id]
    # 
    # Sets @post, @content and @container variables
    def get_post
      @post ||= Post.find(params[:id])
      @content ||= @post.content
      @container ||= @post.container
    end

    # Filter for actions that require the Post has a Content with attached media options
    def post_has_media
      get_post
      bad_request("Content doesn't have media") unless @post.content.content_options[:has_media]
    end

    # Set Bad Request response    
    def bad_request(message = "Bad Request")
      respond_to do |format|
        format.html { 
          render :text => message, :status => 400 
        }
        format.atom {
          head :bad_request
        }
      end
    end
end
