module CMS
  module Controller
    # Common Methods for CMS Controllers and Helpers
    module Base
      # Inclusion hook to make container_content methods
      # available as ActionView helper methods.
      def self.included(base) #:nodoc:
        base.helper_method :current_site
        base.helper_method :current_container
      end

      def current_site
        @current_site ||= Site.current
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

      # Find current Container using:
      # * path from the request
      # * session
      def current_container
        #FIXME: optimize container search
        @container || get_container_from_path || get_container_from_session 
      end

      # Store the given container_id and container_type in the session.
      def current_container=(new_container)
        if new_container.nil?
          session[:container_id] = session[:container_type] = nil
        else
          session[:container_id]   = new_container.id
          session[:container_type] = new_container.class.to_s
        end
        @container = new_container
      end

      def get_container_from_path #:nodoc:
        candidates = params.each_key.select{ |k| k[-3..-1] == '_id' }

        for candidate_key in candidates
          begin
            logger.debug candidate_key[0..-4]
            candidate_class = candidate_key[0..-4].to_sym.to_class
          rescue NameError
            next
          end

          next unless candidate_class.respond_to?(:container_options)

          begin
            return @container = candidate_class.find(params[candidate_key])
          rescue ActiveRecord::RecordNotFound
            next
          end
        end

        nil
      end

      def get_container_from_session #:nodoc:
        if session[:container_id] && session[:container_type] && CMS.containers.include?(session[:container_type].tableize.to_sym)
          @container = session[:container_type].constantize.find(session[:container_id])
        end
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
        @container = current_container || current_site

        render(:text => "Forbidden", :status => 403) unless @container.respond_to?("container_options")
      end
    end
  end
end
