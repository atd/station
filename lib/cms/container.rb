module CMS #nodoc#
  module Container
    def self.included(base) #nodoc#
      base.extend ClassMethods
    end

    module ClassMethods
      # Enhances a Model with Container capabilities so Contents can be posted to this
      #
      # Options:
      # * <tt>contents</tt>: limit the contents this container supports. Defaults to all available contents
      #
      def acts_as_container(options = {})
        cattr_reader :contents

        options[:contents] ||= CMS.contents

        options.each_pair do |var, value|
          class_variable_set "@@var".to_sym, value
        end

        has_many :posts, :as => :container,
                         :class_name => "CMS::Post"

        has_many :categories, :as => :owner

        include CMS::Container::InstanceMethods
      end
    end


    # Instance methods can be redefined in each Model for custom features
    module InstanceMethods
      # Does this agent manage the container?
      def has_owner?(agent)
        self == agent
      end

      # Can agent get posts from this container?
      # Note that each post defines it own permissions, thus overwrites this
      def read_by?(agent)
        true
      end

      # Can <tt>agent</tt> post to this container?
      def write_by?(agent)
        self == agent
      end
    end
  end
end
