module CMS
  module ActionController
    module Sessions
      # Methods for Sessions based on LoginAndPassword Authentication 
      module LoginAndPassword
        # Init Session using LoginAndPassword Authentication
        def create_with_login_and_password
          return if params[:login].blank? || params[:password].blank?

          agent = nil

          CMS::ActiveRecord::Agent.authentication_classes(:login_and_password).each do |klass|
            agent = klass.authenticate_with_login_and_password(params[:login], params[:password])
            break if agent
          end

          if agent
            if agent.agent_options[:activation] && ! agent.activated_at
              flash[:notice] = t(:please_activate_account)
            elsif agent.respond_to?(:disabled) && agent.disabled
              flash[:error] = t(:disabled, :scope => agent.class.to_s.tableize)
            else
              self.current_agent = agent
              flash[:notice] = t(:logged_in_successfully)
              redirect_back_or_default(after_create_path)
              return
            end
          else
            flash[:error] ||= t(:invalid_credentials)
          end
          render :action => 'new'
        end
      end
    end
  end
end
