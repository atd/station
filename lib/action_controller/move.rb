module ActionController
  # Base methods for ActionController
  module Move
    # Inclusion hook to make container_content methods
    # available as ActionView helper methods.
    class << self
      def deprecated_method(old_method, new_method)
        module_eval <<-END_METHOD
          def #{ old_method } *args
            logger.debug "CMSplugin: DEPRECATION WARNING \\"#{ old_method }\\". Please use \\"#{ new_method }\\" instead."
            logger.debug "           in: \#{ caller[2] }"
            send :#{ new_method }, *args
          end
          END_METHOD
      end

      def included(base) #:nodoc:
        base.helper_method :site
        base.helper_method :current_site
        base.helper_method :container
        base.helper_method :current_container
        base.helper_method :categories_domain

        class << base
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
    end

    # Returns the Model Class related to this Controller 
    #
    # e.g. Attachment for AttachmentsController
    #
    # Useful for Controller inheritance
    def model_class
      @model_class ||= controller_name.classify.constantize
    end

    # Obtains a given ActiveRecord from parameters. 
    # Options:
    # * acts_as: the ActiveRecord model must acts_as the given symbol.
    #   acts_as => :container
    def record_from_path(options = {})
      acts_as_module = "ActiveRecord::#{ options[:acts_as].to_s.classify }".constantize if options[:acts_as]

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
          return instance_variable_set("@#{ options[:acts_as] }", candidate_class.find(params[candidate_key]))
        rescue ::ActiveRecord::RecordNotFound
          next
        end
      end

      nil
    end

    def site
      @site ||= Site.current
    end

    deprecated_method :current_site, :site
  
    # Find current Container using:
    # * path from the request
    # * session
    def container
      #FIXME: optimize container search
      @container || get_container_from_path || get_container_from_session 
    end

    deprecated_method :current_container, :container
    deprecated_method :get_container, :container

    # Tries to find a Container suitable for this Content
    # 
    # Calls container to figure out from params. If unsuccesful, 
    # it tries with site
    # 
    # Renders Forbidden if no Container is found
    def container!
      @container = container || site

      render(:text => "Container not present", :status => :precondition_failed) unless @container.respond_to?("container_options")
    end

    deprecated_method :needs_container, :container!

    # Store the given container_id and container_type in the session.
    def container=(new_container)
      if new_container.nil?
        session[:container_id] = session[:container_type] = nil
      else
        session[:container_id]   = new_container.id
        session[:container_type] = new_container.class.to_s
      end
      @container = new_container
    end

    deprecated_method :current_container=, :container=

    def get_container_from_path #:nodoc:
      record_from_path(:acts_as => :container)
    end

    def get_container_from_session #:nodoc:
      if session[:container_id] && session[:container_type] && ActiveRecord::Container.symbols.include?(session[:container_type].tableize.to_sym)
        @container = session[:container_type].constantize.find(session[:container_id])
      end
    end

    def categories_domain
      record_from_path(:acts_as => :categories_domain) || site
    end
  end
end
