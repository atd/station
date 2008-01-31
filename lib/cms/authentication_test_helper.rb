module CMS
  module AuthenticationTestHelper
    # FIXME
    # Sets the current agent in the session from the fixtures.
    def login_as(agent)
      @request.session[:agent_id] = agent ? agent(agent).id : nil
    end

    def authorize_as(user)
      @request.env["HTTP_AUTHORIZATION"] = user ? ActionController::HttpAuthentication::Basic.encode_credentials(users(user).login, 'test') : nil
    end
  end
end
