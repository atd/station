module ActiveRecord #:nodoc:
  module Content #:nodoc:
    # Fake ActiveRecord::Base subclass for building queries in Containers
    class Inquirer < ActiveRecord::Base
      @colums = Array.new
      @columns_hash = { "type" => :fake }

      class << self
        def all(options = {}, content_options = {})
          all_query = "SELECT * FROM (#{ query(options.dup, content_options) }) AS contents"

          add_conditions!(all_query, options[:conditions], nil)
          add_group!(all_query, options[:group], options[:having], nil)
          add_order!(all_query, options[:order], nil)
          add_limit!(all_query, options, nil)

          find_by_sql all_query
        end

        def paginate(options = {}, content_options = {})
          options[:order] ||= "updated_at DESC"
          options[:limit]  = options.delete(:per_page) || 30
          page             = options.delete(:page)     || 1
          options[:offset] = ( page.to_i - 1 ) * options[:limit]


          WillPaginate::Collection.create(page, per_page) do |pager|
            contents = all(options)

            pager.replace(contents)

            pager.total_entries = count(options)
          end
        end

        def count(options = {})
          count_by_sql "SELECT COUNT(*) FROM (#{ query(options) }) AS all_contents"
        end

        # Global Inquirer query
        #
        # This method setups the query that is the UNION of quering several containers
        #
        # Options:
        # containers:: the containers that will be queried for contents
        #
        # Content options:
        # columns:: the columns that will be included in each container_query. Defaults to the intersection of all contents columns.
        def query(options = {}, content_options = {})
          containers = Array(options.delete(:containers))

          contents = options[:contents] ||
                     ( containers.any? ?
                         containers.map(&:class).map(&:contents).flatten.uniq :
                         ActiveRecord::Content.symbols )
          contents = contents.map(&:to_class)

          content_options[:columns] ||=
            contents.inject(contents.first.columns.map(&:name)){ |columns, content|
              columns & content.columns.map(&:name)
            }

          containers.any? ?
            containers.map{ |c| container_query(c, content_options.dup) }.join(" UNION ") :
            container_query(nil, content_options)
        end

        # Query per container
        #
        # Options:
        # columns:: The columns included for each content. Same option as in query
        # contents:: The contents that will be included in the query. If container is present, defaults to container's contents. If it's nil, to all the Contents
        def container_query(container, options = {})
          options[:contents] ||=
            ( container.present? ?  
                container.class.contents :
                ActiveRecord::Content.symbols )

          options[:contents].map(&:to_class).map { |content|
            # Need to build query per content
            params = options.dup
            params[:select] ||= params.delete(:columns).join(", ")
            params[:select]  += ", ( SELECT \"#{ content }\" ) AS type"
            params[:select]  += 
              ( content.acts_as?(:resource) &&
                  content.resource_options[:has_media] ?
                    ", content_type" :
                    ", ( SELECT NULL ) AS content_type" )

            content.content_inquirer_query(params, :container => container)
          }.join(" UNION ")
        end
      end
    end
  end
end

