module ActiveRecord #:nodoc:
  module Content
    # Fake ActiveRecord::Base subclass for building queries in Containers
    class Inquirer < ActiveRecord::Base
      @colums = Array.new
      @columns_hash = { "type" => :fake }

      set_table_name "all_contents"

      class << self
        def all(options = {}, container_options = {})
          all_query = "SELECT * FROM (#{ query(options.dup, container_options) }) AS all_contents  "

          add_conditions!(all_query, options[:conditions], nil)
          add_group!(all_query, options[:group], options[:having], nil)
          add_order!(all_query, options[:order], nil)
          add_limit!(all_query, options, nil)

          find_by_sql all_query
        end

        def paginate(options = {}, container_options = {})
          limit  = options.delete(:per_page) || 30
          page   = options.delete(:page)     || 1
          offset = ( page.to_i - 1 ) * limit

          all_options = options.dup
          all_options[:limit]  = limit
          all_options[:offset] = offset 

          WillPaginate::Collection.create(page, limit) do |pager|
            contents = all(all_options, container_options.dup)

            pager.replace(contents)

            pager.total_entries = count(options, container_options)
          end
        end

        def count(options = {}, container_options = {})
          count_query = "SELECT COUNT(*) FROM (#{ query(options, container_options) }) AS all_contents "
          add_conditions!(count_query, options[:conditions], nil)
          add_group!(count_query, options[:group], options[:having], nil)

          count_by_sql count_query
        end

        # Global Inquirer query
        #
        # This method setups the query that is the UNION of quering several containers
        #
        # Options: params of the global query
        #
        # Container options: params of each query
        # containers:: the containers that will be queried for contents
        # contents:: the type of contents that will be included
        # columns:: the columns that will be included in each container_query. Defaults to the intersection of all contents columns.
        def query(options = {}, container_options = {})
          containers = Array(container_options[:containers])

          contents = container_options[:contents] ||
                     ( containers.any? ?
                         containers.map(&:class).map(&:contents).flatten.uniq :
                         ActiveRecord::Content.symbols )
          contents = contents.map(&:to_class)

          container_options[:columns] ||=
            contents.inject([]){ |columns, content|
              columns | content.column_names
            }

          # If asking for the contents of 0 containers, or 0 contents, return empty set
          if container_options.key?(:containers) &&
             container_options[:containers].blank? ||
             container_options.key?(:contents) &&
             container_options[:contents].blank?

            # Return empty set. Sure, there is a better way to do this
            columns = container_options[:columns]
            columns = [ "id" ] if columns.blank?

            columns_sql =
              columns.map{ |c|
                "( SELECT NULL ) AS `#{ c }`"
              }.join(", ")

            return "SELECT * FROM ( SELECT #{ columns_sql }) AS empty WHERE `#{ columns.first }` IS NOT NULL"
          end
           
          #Temporal fix for contents with type column
          container_options[:columns].delete('type')
          
          containers.any? ?
            containers.map{ |c| container_query(c, container_options.dup) }.join(" UNION ") :
            container_query(nil, container_options)
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

            params[:select] ||=
              params.delete(:columns).map{ |c|
                content.column_names.include?(c) ?
                "`#{c}`" :
                "( SELECT NULL ) AS `#{ c }`"
              }.join(", ")
            # Should fix this to support AR STI
            params[:select] += ", ( SELECT \"#{ content }\" ) AS type"
           
            content.content_inquirer_query(params, :container => container)
          }.join(" UNION ")
        end
      end
    end
  end
end

