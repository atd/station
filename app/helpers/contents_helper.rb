module ContentsHelper

  # Separator
  def contents_menu_separator
    '<hr class="separator" />'
  end

  # Menu for container contents
  #
  # Options:
  #   container:: Set to false it ignores the container
  def contents_menu(options = {})
    options[:contents]  ||= contents_list(options)
    options[:container] = true if options[:container].nil?
    container = options[:container] ? self.container : nil

    returning "" do |menu|
      options[:contents].each do |content|
        content_link = polymorphic_path([ container, content.to_class.new ])
        menu << link_to("<span id=\"content_link_#{ content.to_s.tableize }\"> » #{ t(content.to_s.singularize, :count => :other) } </span>", content_link, {:class => "content_link #{ controller.controller_name == content.to_s.pluralize ? "active" : "inactive" } button" })
     end
    end
  end

  def new_content_button
    logger.debug "DEPRECATION WARNING: new_content_button is deprecated. Use new_contents_menu"
    new_contents_menu
  end

  # Display buttons for add contents to current_container
  def new_contents_menu(options = {})
    options[:contents]  ||= contents_list(options)
    options[:container] = true if options[:container].nil?
    container = options[:container] ? self.container : nil

    returning "" do |html|
      html << "<div id=\"content_new_top\" class=\"block_white_top\">» #{ t('create_') } </div>"
      html << "<div id=\"content_new_center\" class=\"block_white_center\">"

      options[:contents].each do |content|
        html << link_to(t(:new, :scope => content.to_s.singularize),
                        new_polymorphic_path([ container, 
                                               content.to_class.new ]), 
                                             {:class => "action add" })
      end

      html << "</div>"
      html << "<div id=\"content_new_bottom\" class=\"block_white_bottom\"></div><br />"
    end
  end

  # List of contents available for this view
  #
  # Options:
  #   container:: Set to false it ignores the container
  #
  def contents_list(options = {})
    options[:container] ||= true

    ( options[:container] && container ?
        container.class.container_options[:contents] :
        ActiveRecord::Content.symbols 
    ).sort { |a, b| 
      t(a.to_s.singularize, :count => :other) <=>
      t(b.to_s.singularize, :count => :other)
    }
  end

  # Show info about the Content
  def content_info(content = nil)
    content ||= @content

    returning "" do |html|
      html <<  "<div id=\"content_info_top\" class=\"block_white_top\">» #{ t('detail.other') } </div>"
      html << "<div id=\"content_info_center\" class=\"block_white_center\">#{ render(:partial => "contents/info", :locals => { :content => content } ) if content }</div>"
      html << "<div id=\"content_info_bottom\" class=\"block_white_bottom\"></div>"
    end
  end
end

