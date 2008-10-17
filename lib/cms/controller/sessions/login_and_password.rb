module CMS
  module Controller
    module Sessions
      # Methods for Sessions based on LoginAndPassword Authentication 
      module LoginAndPassword
        # Init Session using LoginAndPassword Authentication
        def create_with_login_and_password
          return if params[:login].blank? || params[:password].blank?

          agent = nil

          CMS::Agent.authentication_classes(:login_and_password).each do |klass|
            agent = klass.authenticate_with_login_and_password(params[:login], params[:password])
            break if agent
          end

          if agent
            if agent.agent_options[:activation] && ! agent.activated_at
              flash[:notice] = "Please confirm your registration".t
            elsif agent.respond_to?(:disabled) && agent.disabled
              flash[:notice] = "Disabled #{ agent.class.to_s }".t
            else
              self.current_agent = agent
              flash[:notice] = "Logged in successfully".t
              redirect_back_or_default(after_create_path)
              return
            end
          else
            flash[:error] ||= "Wrong credentials".t
          end
          render :action => 'new'
        end
      end
    end
  end
end
