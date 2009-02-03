class LogotypesController < ApplicationController
  include ActionController::Logotypes

  before_filter :get_logotypable_from_path
end
