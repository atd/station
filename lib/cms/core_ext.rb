unless Symbol.instance_methods.include? 'to_class'
  Symbol.class_eval do
    def to_class
      self.to_s.classify.constantize
    rescue NameError
      "CMS::#{ self.to_s.classify }".constantize
    end
  end
end

# Return symbol for polymorphic_path because Site it is a single resource
#
# Example:
#   # current_container = Site.current
#   polymorphic_path([ current_container, Category.new ]) #=> site_categories_path
unless ActionController::PolymorphicRoutes.respond_to?(:polymorphic_url_with_cms)
  ActionController::PolymorphicRoutes.module_eval do
    def polymorphic_url_with_cms(record_or_hash_or_array, options = {}) #:nodoc:
      rhoa = case record_or_hash_or_array
             when Array
               record_or_hash_or_array.map{ |r| filter_single_resources(r) }.compact
             else
               filter_single_resources(record_or_hash_or_array)
             end
      polymorphic_url_without_cms(rhoa, options)
    end

    def filter_single_resources(record) #:nodoc:
      case record
      when Site
        :site
      else
        record
      end
    end

    alias_method_chain :polymorphic_url, :cms
  end
end

unless ActionView::Helpers::AtomFeedHelper.respond_to?(:atom_entry)
  ActionView::Helpers::AtomFeedHelper.module_eval do
    def atom_service(record, current_agent, options = {}, &block)
      xml = options[:xml] || eval("xml", block.binding)
      xml.instruct!

      xml.service "xmlns" => "http://www.w3.org/2007/app", "xmlns:atom" => 'http://www.w3.org/2005/Atom' do
      # Workspaces are Containers current_agent can post to:
      for container in record.stages.select{ |s| s.authorizes?(current_agent, [ :read, :Content ]) }
        xml.workspace do
          xml.tag!( "atom:title", container.name )
            # Collections are different type of Contents
            for content in container.accepted_content_types
              xml.collection(:href => polymorphic_path([ container, content.to_class.new ]) + '.atom') do
                xml.tag!("atom:title", "#{ container.name } - #{ content.to_class.named_collection }")
                xml.accept(container.authorizes?(current_agent, [ :create, :Content ]) ? content.to_class.accepts : nil)
              end
            end
          end
        end
      end
    end

    def atom_entry(record, options = {}, &block)
      if options[:schema_date]
        options[:schema_date] = options[:schema_date].strftime("%Y-%m-%d") if options[:schema_date].respond_to?(:strftime)
      else
        options[:schema_date] = "2005" # The Atom spec copyright date
      end

      xml = options[:xml] || eval("xml", block.binding)
      xml.instruct!

      entry_opts = {"xml:lang" => options[:language] || "en-US", "xmlns" => 'http://www.w3.org/2005/Atom'}
      entry_opts.merge!(options).reject!{|k,v| !k.to_s.match(/^xml/)}

      xml.entry(entry_opts) do
        xml.id("tag:#{request.host},#{options[:schema_date]}:#{record.class}/#{record.id}")

        if options[:published] || (record.respond_to?(:created_at) && record.created_at)
          xml.published((options[:published] || record.created_at).xmlschema)
        end

        if options[:updated] || (record.respond_to?(:updated_at) && record.updated_at)
          xml.updated((options[:updated] || record.updated_at).xmlschema)
        end

        xml.link(:rel => 'alternate', :type => 'text/html', :href => options[:root_url] || polymorphic_url(record))
        xml.link(:rel => 'self', :type => 'application/atom+xml', :href => options[:url] || request.url)

        yield ActionView::Helpers::AtomFeedHelper::AtomFeedBuilder.new(xml, self, options)
      end
    end
  end
end

