# Controllers for every Content inherit this
class CMS::ContentsController < ApplicationController
  include CMS::ControllerMethods
  include CMS::Authentication

  before_filter :authentication_required, :except => [ :index, :show ]

  # Content list filters
  before_filter :get_container,       :only   => [ :index ]
  before_filter :can_read_container,  :only   => [ :index ]
  
  # Content creation filters
  before_filter :needs_container,     :only   => [ :new, :create ]
  before_filter :can_write_container, :only   => [ :new, :create ]

  # Content show filters
  before_filter :get_content,         :except => [ :index, :new, :create ]
  before_filter :can_read_content,    :only   => [ :show ]

  # List Contents of this type posted to a Container
  #
  # When there is no Container requested, just deliver public Contents
  #
  #   GET /:container_type/:container_id/contents
  #   GET /contents
  def index
    # We search for specific contents if the container or the application supports them
    if (@container || CMS).contents.include?(controller_name.to_sym)
      conditions = [ "cms_posts.content_type = ?", controller_name.classify ]
      content_class = controller_name.classify.constantize
    else
      # This Container don't accept the Content type
      render :text => "Doesn't support this Content type", :status => 400
      return
    end

    if @container
      @title ||= "#{ content_class.content_options[:collection].to_s.humanize } - #{ @container.name }"
      # All the Contents this Agent can read in this Container
      @collection = @container.posts.find(:all,
                                          :conditions => conditions,
                                          :order => "updated_at DESC").select{ |p|
        p.read_by?(current_agent)
      }

      # Paginate them
      @posts = @collection.paginate(:page => params[:page], :per_page => content_class.content_options[:per_page])
      @updated = @collection.blank? ? @container.updated_at : @collection.first.updated_at
      @collection_path = container_contents_url
    else
      @title ||= content_class.collection.to_s.humanize
      conditions = merge_conditions("AND", conditions, [ "public_read = ?", true ])
      @posts = CMS::Post.paginate :all,
                                  :conditions => conditions,
                                  :page =>  params[:page],
                                  :order => "updated_at DESC"
      @updated = @posts.blank? ? Time.now : @posts.first.updated_at
      @collection_path = url_for :controller => controller_name
    end

    respond_to do |format|
      format.html
      format.js
      format.xml { render xml => @posts.to_xml }
      format.atom { render :template => 'posts/index.atom.builder', :layout => false }
    end
  end

  # Show this Content
  #   GET /:content_type/:id
  def show
    respond_to do |format|
      format.html # show.rhtml
      format.xml { render :xml => @content.to_xml }

      # Add Content format Mime Type for content with Attachments
      format.send(@content.mime_type.to_sym.to_s) {
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
    @collection_path = container_contents_url
    @post = CMS::Post.new
    @content = instance_variable_set "@#{controller_name.singularize}", controller_name.classify.constantize.new
    render :template => "posts/new"
  end

  # Create a new Content
  #
  #   POST /:container_type/:container_id/contents
  #   POST /contents
  def create
    # FIXME: we should look for an existing content instead of creating a new one
    # every time a Content is posted.
    # Idea: Should use SHA1 on one or some relevant Content field(s) 
    # and find_or_create_by_sha1
    @content = instance_variable_set "@#{controller_name.singularize}", controller_name.classify.constantize.create(params[:content])

    @post = CMS::Post.new(params[:post].merge({ :agent => current_agent,
                                                :container => @container,
                                                :content => @content }))

    respond_to do |format| 
      format.html {
        if !@content.new_record? && @post.save
          flash[:message] = "#{ @content.class.to_s } created"
          redirect_to post_url(@post)
        else
          @content.destroy unless @content.new_record?
          @collection_path = container_contents_url
          render :template => "posts/new"
        end
      }

      format.atom {
        if !@content.new_record? && @post.save
	  headers["Location"] = formatted_post_url(@post, :atom)
	  headers["Content-type"] = 'application/atom+xml'
          render :partial => "posts/entry",
                             :status => :created,
                             :locals => { :post => @post,
                                          :content => @content },
                             :layout => false
        else
          @content.destroy unless @content.new_record?
          render :xml => @post.errors.to_xml, :status => :bad_request
        end
      }
    end
  end

  protected

    def get_content # :nodoc:
      @content = controller_name.classify.constantize.find params[:id]
    end

    def can_read_content # :nodoc:
      access_denied unless @content.read_by?(current_agent)
    end
end
