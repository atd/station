module CMS
  module Controller
    # Controller methods and default filters for Posts Controllers
    module Posts
      # Include some modules by default
      def self.included(base)
        base.send :include, CMS::Controller::Base unless base.instance_methods.include?('resource_class')
        base.send :include, CMS::Controller::Authorization unless base.instance_methods.include?('method_missing_with_authorization_filters')
      end
    
      # List Posts belonging to Container
      #
      # List public posts when no Container is specified
      #
      #   GET /:container_type/:container_id/posts
      #   GET /posts
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
          @posts = CMS::Post.paginate :all,
                                      :conditions => [ "public_read = ?", true ],
                                      :page =>  params[:page],
                                      :order => "updated_at DESC"
          @updated = @posts.blank? ? Time.now : @posts.first.updated_at
          @collection_path = url_for :controller => controller_name
        end
    
        respond_to do |format|
          format.html
          format.atom
          format.xml { render xml => @posts.to_xml }
        end
      end
    
      # Show this Post
      #   GET /posts/:id
      def show
        @title ||= @post.title
    
        respond_to do |format|
          format.html
          format.xml { render :xml => @post.to_xml }
          format.atom { 
            headers["Content-type"] = 'application/atom+xml'
            render :partial => "posts/entry",
                               :locals => { :post => @post },
                               :layout => false
          }
        end
      end
    
      # Renders form for editing this Post metadata
      #   GET /posts/:id/edit
      def edit
        get_params_title_and_description(@post)
    
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
        unless @post.content.content_options[:has_media]
          @content = @post.content.class.create params[:content]
        end
    
        # Avoid the user changes container through params
        params[:post][:container] = @post.container
        params[:post][:agent]     = current_agent
        params[:post][:content]   = @content
    
        respond_to do |format|
          format.html {
            if !@content.new_record? && @post.update_attributes(params[:post])
              flash[:notice] = "#{ @content.class.to_s } updated"
              redirect_to post_url(@post)
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
    
      # Manage Post media (if Post has media)
      # Retreive media
      #   GET /posts/:id/media 
      # Update media
      #   PUT /posts/:id/media 
      def media
        if request.get?
          # Render media file
          @content = @post.content
    
          headers["Content-type"] = @content.mime_type.to_s
          send_data @content.current_data, :filename => @content.filename,
                                           :type => @content.content_type,
                                           :disposition => @content.class.content_options[:disposition].to_s
        elsif request.put?
          # Have to set write post filter here
          # because doesn't apply to GET
          unless @post.write_by? current_agent
            access_denied
            return
          end
    
          # Set params when putting raw data
          set_params_from_raw_post
    
          # TODO: find content if it already exists
          @content = @post.content.class.create(params[:content])
    
          respond_to do |format|
            format.html {
              if !@content.new_record?
                @post.update_attribute :content, @content
                flash[:notice] = "#{ @content.class.to_s } updated"
                redirect_to post_url(@post)
              else
                render :template => "posts/edit_media"
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
          format.html { redirect_to container_contents_url }
          format.atom { head :ok }
          # FIXME: Check AtomPub, RFC 5023
    #      format.send(mime_type) { head :ok }
          format.xml { head :ok }
        end
      end
    
      protected
    
        # Find CMS::Post using params[:id]
        # 
        # Sets @post, @content and @container variables
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
    
        # Filter for actions that require the Post has a Content with attached media options
        def post_has_media
          bad_request unless @post.content.content_options[:has_media]
        end
    
        # Set Bad Request response    
        def bad_request
          respond_to do |format|
            format.html { 
              render :text => "Content doesn't have media", :status => 400 
            }
            format.atom {
              head :bad_request
            }
          end
        end
    end
  end
end
