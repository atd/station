module CMS
  # CMS Helper methods
  # Use them in any of your helpers
  module HelperMethods
    def content_url(content)
      if content.mime_type.blank?
        polymorphic_url(content)
      else
        send "formatted_#{ content.class.to_s.underscore }_url", content, content.mime_type.to_sym
      end
    end
  end
end
