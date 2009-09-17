module ActiveRecord #:nodoc:
  module Authorization #:nodoc:
    # Access Control List (ACL)
    class ACL
      attr_reader :base
      attr_reader :entries

      def initialize(base, entries = Hash.new([]))
        @base, @entries = base, entries
      end

      # Add new entry to this Access Control List
      #
      # The entry must be an Array like:
      #   [ agent, "update", "articles" ]
      # or
      #   [ agent, ACLPermission ]
      def <<(entry)
        agent = entry.shift
        @entries[agent] |= Array(ACLPermission(entry))
        self
      end

      # Appends acl.entries to this ACL
      def concat(acl)
        case acl
        when ACL
          acl.entries.each_pair do |agent, permissions|
            @entries[agent] |= permissions
          end
        when Array
          acl.each do |ace|
            self << ace
          end
        else
          raise "Argument must be ACL or Array: #{ acl.inspect }"
        end
        self
      end

      # Returns a new ACL which entries are the sum
      def +(acl)
        dup.concat(acl)
      end

      def authorize?(permission, options = {})
        permission = ACLPermission(permission)
        agent = options[:to] || Anyone.current

        @entries[agent].include?(permission) ||
        ! agent.is_a?(Anyone) && @entries[Anyone.current].include?(permission) ||
        ! agent.is_a?(SingularAgent) && @entries[Authenticated.current].include?(permission)
      end

      def dup
        self.class.new(@base, @entries.dup)
      end

      def inspect
        base_name = base.respond_to?(:name) && base.name || base.inspect
        "<ACL @base=#{ base_name }, @entries=[#{ inspect_entries }]>"
      end

      # Add to this ACL all the entries from acl which ACLObjective == reflection. 
      # The new entries added will have nil as ACLObjective
      #
      # This is useful for transferring permissions through reflections:
      #
      #   project.acl #=> < "Anyone" => [ "read tasks" ]>
      #
      #   task.import_reflection_acl project.acl, 'tasks' #=> <"Anyone" => [ "read" ]>
      #
      def import_reflection_acl(acl, reflection = base.class)
        acl.entries.each_pair do |agent, permissions|
          permissions.each do |perm|
            self << [ agent, perm.action ] if perm.objective?(reflection)
          end
        end
      end

      def inspect_entries
        returning "" do |s|
          @entries.each_pair do |agent, permissions|
            agent_s = agent.respond_to?(:name) && "\"#{ agent.name }\"" || agent.inspect
            s << "<#{ agent_s } => [ "
            s << permissions.map { |perm|
                   perm_s = "\"#{ perm.action.to_s }"
                   perm_s += " #{ perm.objective.to_s }" if perm.objective.present?
                   perm_s += '"'
                 }.join(", ")
            s << "]> "
          end
        end
      end

      # Normalize ACLPermission p
      def ACLPermission(p)
        case p
        when ACLPermission
          p
        else
          ACLPermission.new(*p)
        end
      end
    end
  end
end

