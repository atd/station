module ActionController
  # Base methods for ActionController
  module Station
    # Inclusion hook to make container_content methods
    # available as ActionView helper methods.
    class << self
      def deprecated_method(old_method, new_method)
        module_eval <<-END_METHOD
          def #{ old_method } *args
            logger.debug "Station: DEPRECATION WARNING \\"#{ old_method }\\". Please use \\"#{ new_method }\\" instead."
            line = caller.select{ |l| l =~ /^\#{ RAILS_ROOT }/ }.first
            logger.debug "           in: \#{ line }"
            send :#{ new_method }, *args
          end
          END_METHOD
      end

      def included(base) #:nodoc:
        base.helper_method :current_site
        base.helper_method :site
        base.helper_method :current_container
        base.helper_method :container
        base.helper_method :categories_domain
        base.helper_method :current_categories_domain

        class << base
          def model_class
            @model_class ||= controller_name.classify.constantize
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
    end

    # Returns the Model Class related to this Controller 
    #
    # e.g. Attachment for AttachmentsController
    #
    # Useful for Controller inheritance
    def model_class
      self.class.model_class
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
          record = candidate_class.find_with_param(params[candidate_key])
          instance_variable_set("@#{ options[:acts_as] }", record) if options[:acts_as]
          instance_variable_set("@#{ candidate_class.to_s.underscore }", record)
          return record
        rescue ::ActiveRecord::RecordNotFound
          next
        end
      end

      nil
    end

    def current_site
      @site ||= Site.current
    end

    deprecated_method :site, :current_site
  
    # Find current Container using path from the request
    def current_container
      @container ||= record_from_path(:acts_as => :container)
    end

    deprecated_method :container, :current_container
    deprecated_method :get_container, :current_container

    # Tries to find a Container suitable for this Content
    # 
    # Calls container to figure out from params. If unsuccesful, 
    # it tries with site
    # 
    # Renders Forbidden if no Container is found
    def current_container!
      @container = container || site

      render(:text => "Container not present", :status => :precondition_failed) unless @container.respond_to?("container_options")
    end

    deprecated_method :container!, :current_container!
    deprecated_method :needs_container, :current_container!

    def current_categories_domain
      record_from_path(:acts_as => :categories_domain) || site
    end

    deprecated_method :categories_domain, :current_categories_domain

    protected

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

      params[content]                  ||= {}
      params[content][:title]          ||= filename
      params[content][:media]          ||= file
      params[content][:public_read]    ||= true
    end
  end
end
