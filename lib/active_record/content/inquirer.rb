module ActiveRecord #:nodoc:
  module Content #:nodoc:
    # Fake ActiveRecord::Base subclass for building queries in Containers
    class Inquirer < ActiveRecord::Base
      @colums = Array.new
      @columns_hash = { "type" => :fake }

      class << self
        # Global Inquirer query
        #
        # Options:
        # columns:: the columns that will be included in each container_query. Defaults to the intersection of all contents columns.
        # containers:: the containers that will be queried for contents
        def query(options = {})
          containers = Array(options.delete(:containers))

          contents = options[:contents] ||
                     ( containers.any? ?
                         containers.map(&:class).map(&:contents).flatten.uniq :
                         ActiveRecord::Content.symbols )
          contents = contents.map(&:to_class)

          options[:columns] ||=
            contents.inject(contents.first.columns.map(&:name)){ |columns, content|
              columns & content.columns.map(&:name)
            }

          containers.any? ?
            containers.map{ |c| container_query(c, options) }.join(" UNION ") :
            container_query(nil, options)
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

        def all(options = {})
          order     = options.delete(:order)    || "updated_at DESC"
          per_page  = options.delete(:per_page) || 30
          page      = options.delete(:page)     || 1
          offset = ( page.to_i - 1 ) * per_page

          WillPaginate::Collection.create(page, per_page) do |pager|
            contents = find_by_sql "SELECT * FROM (#{ query(options.dup) }) AS contents ORDER BY contents.#{ order } LIMIT #{ per_page } OFFSET #{ offset }"
            pager.replace(contents)

            pager.total_entries = count(options)
          end
        end

        def count(options = {})
          count_by_sql "SELECT COUNT(*) FROM (#{ query(options) }) AS all_contents"
        end
      end
    end
  end
end

