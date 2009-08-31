module ActiveRecord #:nodoc:
  module Authorization #:nodoc:
    # Access Control List (ACL)
    class ACL
      attr_reader :base
      attr_reader :entries

      def initialize(base, entries = [])
        @base = base
        @entries = entries.map{|e| ACE(e)}
      end

      def <<(ace)
        ace = ACE(ace)
        @entries << (ace) unless @entries.include?(ace)
        self
      end

      # Appends acl.entries to this ACL
      def concat(acl)
        acl_entries = case acl
                      when ACL
                        acl.entries
                      when Array
                        acl
                      else
                        raise "Argument must be ACL or Array: #{ acl.inspect }"
                      end

        acl_entries.each do |ace|
          self << ace
        end
      end

      # Returns a new ACL which entries are the sum
      def +(acl)
        dup.concat(acl)
      end

      def authorize?(permission, options = {})
        agent = options[:to]

        candidates = entries.select(&:anyone?)

        if agent.present?
          candidates |= entries.select{ |e| e.agent?(agent) }

          if agent.is_a?(Authenticated) || ! agent.is_a?(SingularAgent)
            candidates |= entries.select{ |a| a.agent?(Authenticated.current) }
          end
        end

        candidates.delete_if{ |c| ! c.permission?(*permission) }

        candidates.any?
      end

      def count
        @entries.count
      end

      def dup
        self.class.new(@base, @entries.dup)
      end

      def inspect
        "<ACL @base=#{ base.inspect }, @entries=#{ @entries.inspect }>"
      end

      def ACE(ace)
        case ace
        when ACE
          ace
        else
          ACE.new(*ace)
        end
      end
    end
  end
end

