module ActiveRecord #:nodoc:
  module Content
    class InquirerProxy

      def initialize(owner, scope = {})
        @owner, @scope = owner, scope
      end

      def all(options = {})
        ActiveRecord::Content::Inquirer.all(@scope.merge(options), container_options)
      end

      def paginate(options = {})
        ActiveRecord::Content::Inquirer.paginate(@scope.merge(options), container_options)
      end

      def count(options = {})
        ActiveRecord::Content::Inquirer.count(@scope.merge(options), container_options)
      end

      private
      # Forwards any missing method call to the \target.
      def method_missing(method, *args)
        if load_target
          unless @target.respond_to?(method)
            message = "undefined method `#{method.to_s}' for \"#{@target}\":#{@target.class.to_s}"
            raise NoMethodError, message
          end
 
          if block_given?
            @target.send(method, *args) { |*block_args| yield(*block_args) }
          else
            @target.send(method, *args)
          end
        end
      end
        
      def load_target
        @target ||= (@owner.new_record? ?
                      [] :
                      ActiveRecord::Content::Inquirer.all(@scope, container_options))
      end
      
      def container_options
        {:containers => @owner}
      end

    end
  end
end