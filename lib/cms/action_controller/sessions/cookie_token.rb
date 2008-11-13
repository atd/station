module CMS
  module ActionController
    module Sessions
      # Methods for Sessions based on CookieToken Authentication 
      #
      # CookieToken remembers the Autnentication in the browser for certain amount of time
      module CookieToken
        # Destroy CookieToken Session data
        def destroy_with_cookie_token
          current_agent.forget_me if authenticated?
          cookies.delete :auth_token
        end
      end
    end
  end
end
