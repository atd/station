class ContentGenerator < ScaffoldGenerator
  def banner
    "Usage: #{$0} content ModelName [field:type, field:type]"
  end

  def scaffold_views
    %w[ index show new edit ]
  end
end
