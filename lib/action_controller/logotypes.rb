module ActionController #:nodoc:
  module Logotypes
    class << self
      def included(base) #:nodoc:
        base.send :include, ActionController::Move unless base.ancestors.include?(ActionController::Move)
      end
    end

    def show
      @logotype = ( 
        @logotypable ? 
        @logotypable.logotype : 
        model_class.find(params[:id]) 
      )

      @logotype = 
        @logotype.thumbnails.find_by_thumbnail(params[:thumbnail]) if params[:thumbnail]

      send_data @logotype.current_data, :filename => @logotype.filename,
                                        :type => @logotype.content_type,
                                        :disposition => 'inline'

    end

    private

    def get_logotypable_from_path #:nodoc:
      record_from_path(:acts_as => :logotypable)
    end
  end
end
