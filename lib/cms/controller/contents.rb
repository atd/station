module CMS
  module Controller
    # Controller methods and default filters for Agents Controllers
    module Contents
      def self.included(base) #:nodoc:
        base.send :include, CMS::Controller::Base unless base.instance_methods.include?('resource_class')
        base.send :include, CMS::Controller::Authorization unless base.instance_methods.include?('method_missing_with_authorization_filters')
      end

      # List Contents of this type posted to a Container
      #
      # When there is no Container requested, just deliver public Contents
      #
      #   GET /:container_type/:container_id/contents
      #   GET /contents
      def index(&block)
        # We search for specific contents if the container or the application supports them
        if (@container && @container.container_options[:contents] || CMS.contents).include?(self.resource_class.collection)
          conditions = [ "cms_posts.content_type = ?", self.resource_class.to_s ]
        else
          # This Container don't accept the Content type
          render :text => "Doesn't support this Content type", :status => 400
          return
        end
    
        if @container
          @title ||= "#{ self.resource_class.named_collection } - #{ @container.name }"
          # All the Contents this Agent can read in this Container
          @collection = @container.container_posts.find(:all,
                                                        :conditions => conditions,
                                                        :order => "updated_at DESC").select{ |p|
            p.read_by?(current_agent)
          }
    
          # Paginate them
          @posts = @collection.paginate(:page => params[:page], :per_page => self.resource_class.content_options[:per_page])
          @updated = @collection.blank? ? @container.updated_at : @collection.first.updated_at
          @collection_path = container_contents_url
        else
          @title ||= "Public #{ self.resource_class.named_collection }"
          conditions = merge_conditions("AND", conditions, [ "public_read = ?", true ])
          @posts = CMS::Post.paginate :all,
                                      :conditions => conditions,
                                      :page =>  params[:page],
                                      :order => "updated_at DESC"
          @updated = @posts.blank? ? Time.now : @posts.first.updated_at
          @collection_path = url_for :controller => controller_name
        end
    
        if block
          yield
        else
          respond_to do |format|
            format.html
            format.js
            format.xml { render xml => @posts.to_xml }
            format.atom { render :template => 'posts/index.atom.builder', :layout => false }
          end
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
        @collection_path = container_contents_url
        @post = CMS::Post.new
        @post.content = @content = instance_variable_set("@#{controller_name.singularize}", controller_name.classify.constantize.new)
        render :template => "posts/new"
      end
    
      # Create a new Content
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
              if @content.new_record?
                render :xml => @content.errors.to_xml, :status => :bad_request
              else
                @content.destroy unless @content.new_record?
                render :xml => @post.errors.to_xml, :status => :bad_request
              end
            end
          }
        end
      end
    
      protected
    
        def get_content # :nodoc:
          @content = resource_class.find params[:id]
        end
    
        def can_read_content # :nodoc:
          access_denied unless @content.read_by?(current_agent)
        end
    end
  end
end
