module CMS
  module Agent
    # Remember Agent in current browser through cookies
    module Remember
      def remember_token?
        remember_token_expires_at && Time.now.utc < remember_token_expires_at 
      end

      # Remember Agent in this browser for 2 weeks
      def remember_me
        remember_me_for 2.weeks
      end

      def remember_me_for(time) #:nodoc:
        remember_me_until time.from_now.utc
      end

      def remember_me_until(time) #:nodoc:
        self.remember_token_expires_at = time
        self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
        save(false)
      end

      # Remove Remember information
      def forget_me
        self.remember_token_expires_at = nil
        self.remember_token            = nil
        save(false)
      end
    end
  end
end
