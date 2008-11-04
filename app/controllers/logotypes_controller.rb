class LogotypesController < ApplicationController
  before_filter :get_logotypable_from_path

  def show
    @logotype = ( @logotypable ? @logotypable.logotype : Logotype.find(params[:id]) )

    @logotype = @logotype.thumbnails.find_by_thumbnail(params[:thumbnail]) if params[:thumbnail]

    send_data @logotype.current_data, :filename => @logotype.filename,
                                      :type => @logotype.content_type,
                                      :disposition => 'inline'

  end

  private

  def get_logotypable_from_path #:nodoc:
    get_resource_from_path(:acts_as => :logotypable)
  end
end
