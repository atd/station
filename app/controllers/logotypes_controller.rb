class LogotypesController < ApplicationController
  include CMS::ActionController::Logotypes

  before_filter :get_logotypable_from_path
end
