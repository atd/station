module CMS
  module Controller
    # Common Methods for CMS Controllers and Helpers
    module Base
      # Inclusion hook to make container_content methods
      # available as ActionView helper methods.
      def self.included(base) #:nodoc:
        base.helper_method :current_site
        base.helper_method :current_container

        class << base

          def log_params
            before_filter do |controller|
              logger.debug controller.params.inspect
            end
          end
          # Set params from AtomPub raw post
          def set_params_from_atom(atom_parser, options)
            parser = case atom_parser
                     when Proc
                       atom_parser
                     when Class
                       atom_parser.method(:atom_parser).to_proc
                     when Symbol
                       atom_parser.to_class.method(:atom_parser).to_proc
                     else
                       raise "Invalid AtomParser: #{ atom_parser.inspect }"
                     end

            before_filter options do |controller|
              if controller.request.format == Mime::ATOM
                controller.params = controller.params.merge(parser.call(controller.request.raw_post))
              end
            end
          end
        end
      end

      def current_site
        @current_site ||= Site.current
      end
      
      protected
      # Returns the Model Class related to this Controller 
      #
      # e.g. Attachment for AttachmentsController
      #
      # Useful for Controller inheritance
      def resource_class
        @resource_class ||= controller_name.classify.constantize
      end

      # Obtains a given resource from parameters. 
      # Options:
      # * acts_as: the resource must acts_as the given symbol.
      #   acts_as => :container
      def get_resource_from_path(options = {})
        acts_as_module = "CMS::#{ options[:acts_as].to_s.classify }".constantize if options[:acts_as]

        candidates = params.keys.select{ |k| k[-3..-1] == '_id' }

        candidates.each do |candidate_key|
          # Filter keys that correspond to classes
          begin
            candidate_class = candidate_key[0..-4].to_sym.to_class
          rescue NameError
            next
          end

          # acts_as filter
          if options[:acts_as]
            next unless acts_as_module.classes.include?(candidate_class)
          end

          next unless candidate_class.respond_to?(:find)

          # Find record
          begin
            return instance_variable_set "@#{ options[:acts_as] }", candidate_class.find(params[candidate_key])
          rescue ActiveRecord::RecordNotFound
            next
          end
        end

        nil
      end
     
      # Fills title and description fields from Entry and Content.
      #
      # Useful when rendering forms
      def get_params_title_and_description(entry) #:nodoc:
        params[:title] ||= entry.title
        params[:title] ||= entry.content.title if entry.content.respond_to?("title")
        params[:description] ||= entry.description
        params[:description] ||= entry.content.description if entry.content.respond_to?("description=")
      end
  
      # Fills title and description fields for Entry and Content
      #
      # Useful when POSTing content
      def set_params_title_and_description(content_class) #:nodoc:
        params[:entry] ||= {}
        params[:entry][:title] ||= params[:title]
        params[:entry][:description] ||= params[:description]
        params[:content] ||= {}
        params[:content][:title] ||= params[:title] if content_class.respond_to?("title=")
        params[:content][:description] ||= params[:description] if content_class.respond_to?("description=")
      end
  
      # Extract request parameters when posting raw data
      def set_params_from_raw_post(content = controller_name.singularize.to_sym)
        return if request.raw_post.blank? || params[content]
  
        filename = request.env["HTTP_SLUG"] || controller_name.singularize
        content_type = request.content_type
        
        file = Tempfile.new("media")
        file.write request.raw_post
        (class << file; self; end).class_eval do
          alias local_path path
          define_method(:content_type) { content_type.dup.taint }
          define_method(:original_filename) { filename.dup.taint }
        end
  
        params[:entry]                   ||= {}
        params[:entry][:title]           ||= filename
        params[:entry][:public_read]     ||= true
        params[content]                  ||= {}
        params[content][:media]          ||= file
      end

      # Find current Container using:
      # * path from the request
      # * session
      def current_container
        #FIXME: optimize container search
        @container || get_container_from_path || get_container_from_session 
      end

      alias_method :get_container, :current_container

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
        get_resource_from_path(:acts_as => :container)
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
