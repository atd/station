class TagsController < ApplicationController
  def show
    @taggables = tag.taggables
  end

  private

  def tag
    @tag ||= Tag.find_by_name(params[:id])
    raise ActiveRecord::RecordNotFound, "Tag not found" unless @tag

    @tag
  end
end
