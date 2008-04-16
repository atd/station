module CMS
  module Controller
    # Common Methods for CMS Controllers and Helpers
    module Base
      # Inclusion hook to make container_content methods
      # available as ActionView helper methods.
      def self.included(base)
        base.send :helper_method, :container_contents_path, 
                                  :container_contents_url, 
                                  :new_container_content_path, 
                                  :new_container_content_url
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
  
        params[:title]                  ||= filename
        params[:post]                   ||= {}
        params[:post][:public_read]     ||= true
        params[:content]                ||= {}
        params[:content][:filename]     ||= filename
        params[:content][:content_type] ||= request.content_type
        params[:content][:raw_post]     ||= request.raw_post
      end
      
      ##################################################################
      # TODO: DRY!!!
      
      # Return the path to this Content collection in this Container 
      #
      # Options:
      # <tt>:content</tt>: symbol describing the type of content. Defaults to controller.controller_name
      # <tt>:container </tt>: Container instance the Content will be posted to. Defaults to @container
      def container_contents_path(options = {})
        container_content_options(options) do |container, content, cc_options|
          send(( container ? "container_#{ content }_path" : "#{ content }_path" ), cc_options)
        end
      end
  
      # Return the path to new Content in this Container 
      #
      # Options:
      # <tt>:content</tt>: symbol describing the type of content. Defaults to controller.controller_name.singularize
      # <tt>:container </tt>: Container instance the Content will be posted to. Defaults to @container
      def new_container_content_path(options = {})      
        container_content_options(options) do |container, content, cc_options|
          send(( container ? "new_container_#{ content.singularize }_path": "new_#{ content }_path" ), cc_options)
        end
      end
  
  
      # Return the url to this Content collection in this Container 
      #
      # Options:
      # <tt>:content</tt>: symbol describing the type of content. Defaults to controller.controller_name
      # <tt>:container </tt>: Container instance the Content will be posted to. Defaults to @container
      def container_contents_url(options = {})
        container_content_options(options) do |container, content, cc_options|
          send(( container ? "container_#{ content }_url" : "#{ content }_url" ), cc_options)
        end
      end
  
      # Return the url to new Content in this Container 
      #
      # Options:
      # <tt>:content</tt>: symbol describing the type of content. Defaults to controller.controller_name.singularize
      # <tt>:container </tt>: Container instance the Content will be posted to. Defaults to @container
      def new_container_content_url(options = {})
        container_content_options(options) do |container, content, cc_options|
          send(( container ? "new_container_#{ content.singularize }_url" : "new_#{ content }_url" ), cc_options)
        end
      end
  
      #TODO: DRY!!!
      ####################################################
  
      def container_content_options(options = {}) # :nodoc:
        content   = options.delete(:content)   || ( respond_to?(:controller) ? controller : self ).controller_name
        container = options.delete(:container) || @container
        
        if container
          options[:container_type] = container.class.to_s.tableize
          options[:container_id]   = container.id
        end
        
        yield(container, content, options)
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
          (@container.container_options[:contents].clone << :posts).include?(controller_name.to_sym)
          @collection_path = container_contents_path
        else
          render(:text => "Forbidden", :status => 403)
        end
      end
  
      # Can the current Agent access this Container?
      def can_read_container
        access_denied if @container && !@container.read_by?(current_agent)
      end
  
      # Can the current Agent post to this Container?
      def can_write_container
        access_denied if @container && !@container.write_by?(current_agent)
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
