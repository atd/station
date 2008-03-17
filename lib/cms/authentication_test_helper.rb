module CMS
  # Athentication helper methods for tests
  module AuthenticationTestHelper
    # Sets the current agent in the session from the fixtures.
    def login_as(agent)
      agent_fixture = find_agent_fixture(agent)

      @request.session[:agent_id] = agent_fixture ? agent_fixture.id : nil
      @request.session[:agent_type] = agent_fixture ? agent_fixture.class.to_s : nil
    end

    # Sets HTTP environment credentials
    def authorize_as(agent)
      agent_fixture = find_agent_fixture(agent)

      @request.env["HTTP_AUTHORIZATION"] = agent_fixture ? ActionController::HttpAuthentication::Basic.encode_credentials(agent_fixture.login, 'test') : nil
    end

    def logged_in_session?
      session[:agent_id] && session[:agent_type]
    end

    private

    # Finds agent fixture among agent classes
    def find_agent_fixture(agent)
      return nil unless agent

      for agent_klass in CMS.agent_classes
        agent_fixture = send(agent_klass.to_s.tableize, agent)
        return agent_fixture if agent_fixture
      end
      nil
    end
  end
end
