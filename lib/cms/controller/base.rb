module CMS
  module Controller
    # Common Methods for CMS Controllers and Helpers
    # == CMS Routes
    # Generate URLs and paths for Contents related to a Container
    # 
    # If you have:
    #   class Space
    #     acts_as_container
    #   end
    #
    #   class Article
    #     acts_as_content
    #   end
    #
    # In your Controller or Views you can use:
    #   @space = Space.find(1)
    #
    #   space_articles_path(@space) # => /spaces/1/articles
    #   formatted_space_articles_path(@space, :format => 'atom') # => /spaces/1/articles.atom
    #   new_space_articles_path(@space) # => /spaces/1/articles/new
    # All methods also work with +_url+ at the end, so you get the complete URL with protocol, host and port
    #   space_articles_url(@space) # => http://localhost:3000/spaces/1/articles
    #
    # You can also use the more generic +container_contents+ methods. 
    # For the same example:
    #   container_contents_path(:container => @space,
    #                           :content => 'articles') # => /spaces/1/articles 
    # If <tt>:container</tt> option is not specified, it defaults to <tt>@container</tt>.
    # <tt>:content</tt> option defaults to <tt>controller_name</tt>
    module Base
      # Inclusion hook to make container_content methods
      # available as ActionView helper methods.
      def self.included(base) #:nodoc:
        # Fix method_missing handling in ActionController::Base#perform_action
        # 
        # method_missing is not defined in ActionController::Base. 
        # When adding alias_method_chains on method_missing
        # we have to define first method_missing 
        # so it is called at the end of the chain
	# FIXME:
	# there is a bug when the method is called from the Helper,
	# it renders the template over and over again
	# so this is now disabled
	#
#        base.class_eval do
#          def method_missing(method, *args, &block)
#            if template_exists? && template_public?
#              default_render
#            else
#              raise ActionController::UnknownAction, "No action responded to #{method}", caller
#            end
#          end
#        end unless base.instance_methods.include?('method_missing')
        
        # Generic method
        send_cms_route_to_helper(base, :container, :content)
        
        # Specific method
        for container in CMS.containers
          for content in container.to_class.container_options[:contents] + [ :posts ]
            send_cms_route_to_helper(base, container, content)
          end
        end
                       
        base.class_eval do
          alias_method_chain :method_missing, :cms_routes
        end  
      end
      
      protected
      # Hook for CMS URLs
      def method_missing_with_cms_routes(method, *args, &block) #:nodoc:         
         if method.to_s =~ /(formatted_|new_|)(.*)_(.*)(_path|_url)/           
          # Sure there is a more elegant way to do this
          action = $1
          container = $2
          content = $3
          type = $4
          
          # We support two types of Routes:
          # classic routes: "container_content" and
          # specific ones: "space_articles"
          if container == "container"
            options = args.shift || {}
            container_instance = options.delete(:container) || @container 
       
            if content =~ /^content/
              content_instance = options.delete(:content) || ( respond_to?(:controller) ? controller : self ).controller_name
              content_instance = content_instance.to_s
              content_instance = content_instance.singularize if action =~ /^new_/
            else
              return method_missing_without_cms_routes(method, *args, &block)
            end
          else
            raise Exception.new("#{ container } is not a valid container") unless CMS.containers.include?(container.pluralize.to_sym)
            container_instance = args.shift
            #TODO filter content class type??
            options = args.first || {}

            content_instance = ( action =~ /^new_/ ? content.singularize : content)
          end
          
          if container_instance
            options[:container_type] = container_instance.class.to_s.tableize
            options[:container_id]   = container_instance.id
          
            send("#{ action }container_#{ content_instance }#{ type }", options)
          else
            send("#{ action }#{ content_instance }#{ type }", options)
          end
        else
          method_missing_without_cms_routes(method, *args, &block)
        end
      end
      
      private
      def self.send_cms_route_to_helper(base, container, content)
        container = container.to_s.singularize
        content = content.to_s
        
        base.send :helper_method, "#{ container }_#{ content.pluralize }_path", 
                                  "#{ container }_#{ content.pluralize }_url", 
                                  "new_#{ container }_#{ content.singularize }_path", 
                                  "new_#{ container }_#{ content.singularize }_url",
                                  "formatted_#{ container }_#{ content.pluralize }_path",
                                  "formatted_#{ container }_#{ content.pluralize }_url"
      end
      
      protected
      # Returns the Model Class related to this Controller 
      #
      # e.g. Article for ArticlesController
      #
      # Useful for Controller inheritance
      def resource_class
        @resource_class ||= controller_name.classify.constantize
      end
      
      # Fills title and description fields from Post and Content.
      #
      # Useful when rendering forms
      def get_params_title_and_description(post) #:nodoc:
        params[:title] ||= post.title
        params[:title] ||= post.content.title if post.content.respond_to?("title")
        params[:description] ||= post.description
        params[:description] ||= post.content.description if post.content.respond_to?("description=")
      end
  
      # Fills title and description fields for Post and Content
      #
      # Useful when POSTing content
      def set_params_title_and_description(content_class) #:nodoc:
        params[:post] ||= {}
        params[:post][:title] ||= params[:title]
        params[:post][:description] ||= params[:description]
        params[:content] ||= {}
        params[:content][:title] ||= params[:title] if content_class.respond_to?("title=")
        params[:content][:description] ||= params[:description] if content_class.respond_to?("description=")
      end
  
      # Extract request parameters when posting raw data
      def set_params_from_raw_post
        return if request.raw_post.blank? || params[:content]
  
        filename = request.env["HTTP_SLUG"] || controller_name.singularize
        content_type = request.content_type
        
        file = Tempfile.new("media")
        file.write request.raw_post
        (class << file; self; end).class_eval do
          alias local_path path
          define_method(:content_type) { content_type.dup.taint }
          define_method(:original_filename) { filename.dup.taint }
        end
  
        params[:title]                  ||= filename
        params[:post]                   ||= {}
        params[:post][:public_read]     ||= true
        params[:content]                ||= {}
        params[:content][:media]        ||= file
      end
        
      # Find Container using path from the request
      def get_container
        return nil unless params[:container_type] && params[:container_id]
  
        @container = params[:container_type].to_sym.to_class.find params[:container_id]
      end
  
      # Tries to find a Container suitable for this Content
      # 
      # Calls get_container to figure out from params. If unsuccesful, 
      # it tries with current_agent
      # 
      # If a Container is found, and this type of content can be posted, 
      # it sets <tt>@container</tt> to the container found,
      # and <tt>@collection_path</tt> to <tt>/:container_type/:container_id/contents</tt>
      # 
      # Renders Forbidden if no Container is found
      def needs_container
        @container = get_container || current_agent
  
        if @container.respond_to?("container_options") && 
          (@container.container_options[:contents].clone + [ :posts, :categories ]).include?(controller_name.to_sym)
          @collection_path = container_contents_path
        else
          render(:text => "Forbidden", :status => 403)
        end
      end
   
      # Merge two conditions arrays using <tt>operator</tt>. 
      # Example:
      #   merge_conditions("AND", [ "public_read = ?", true ], [ "content_type = ?", "Article" ])
      #   # => [ "( public_read = ? ) AND ( content_type = ? )", true, "Article" ]
      def merge_conditions(operator, *conditions)
        query = conditions.compact.map(&:shift).compact.map{ |c| " (#{ c }) "}.join(operator)
        Array(query) + conditions.flatten.compact
      end
    end
  end
end
