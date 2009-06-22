begin
  require 'openid'
  require 'openid/extensions/sreg'
rescue MissingSourceFile
  raise "Station: You need 'ruby-openid' gem for OpenID authentication support"
end

module ActionController #:nodoc:
  module Sessions
    # OpenID sessions management
    module OpenID
      # Create new Session using OpenID
      def create_with_openid
        if !params[:openid_identifier].blank?
          begin
            openid_request = openid_consumer.begin params[:openid_identifier]
          rescue ::OpenID::OpenIDError => e
            flash[:error] = t(:discovery_failed, :id => params[:openid_identifier], :error => e)
            render :action => "new"
            return
          end

          sreg_request = ::OpenID::SReg::Request.new
          # required fields
          sreg_request.request_fields(['nickname', 'email'], true)
          # optional fields
          # sreg_request.request_fields(['fullname'], false)

          #TODO: PAPE, OpenID Provider Authentication Policy
          # see: http://openid.net/specs/
          # papereq = ::OpenID::PAPE::Request.new
          # ...

          return_to = open_id_complete_url
          realm = "http://#{ request.host_with_port }/"

          if openid_request.send_redirect?(realm, return_to)
            redirect_to openid_request.redirect_url(realm, return_to)
          else
            @form_text = openid_request.form_markup(realm, return_to, true, { 'id' => 'openid_form' })
            render :layout => nil
          end
        # OpenID login completion
        elsif params[:open_id_complete]
          # Filter path parameters
          parameters = params.reject{ |k,v| request.path_parameters[k] }
          # Complete the OpenID verification process
          openid_response = openid_consumer.complete(parameters, return_to)

          case openid_response.status
          when ::OpenID::Consumer::SUCCESS
            flash[:notice] = t('openid.client.verification_succeeded_with_id', :id => openid_response.display_identifier)
            uri = Uri.find_or_create_by_uri(openid_response.display_identifier)

            # If already authenticated, add URI to Agent.openid_ownings
            if authenticated? && ! current_agent.openid_uris.include?(uri)
              current_agent.openid_uris << uri
              flash[:notice] = t(:id_attached_to_account, :id => uri)
              return
            end

            ActiveRecord::Agent.authentication_classes(:openid).each do |klass|
              self.current_agent = 
                klass.authenticate_with_openid(uri)
              break if authenticated?
            end

            if authenticated?
              redirect_back_or_default after_create_path
              flash[:notice] = t(:logged_in_successfully)
            else
              # We create new local Agent with OpenID data
              session[:openid_identifier] = openid_response.display_identifier
              sreg_response = ::OpenID::SReg::Response.from_success_response(openid_response)
              redirect_to :controller => ActiveRecord::Agent.authentication_classes(:openid).first.to_s.tableize,
                          :action => "new",
                          :params => {
                            ActiveRecord::Agent.authentication_classes(:openid).first.to_s.tableize => sreg_response.data
                          }
            end
          when ::OpenID::Consumer::FAILURE
            flash[:error] = openid_response.display_identifier ?
              t('openid.client.verification_failed_with_id', :id => openid_response.display_identifier, :message => openid_response.message) :
              t('openid.client.verification_failed', :message => openid_response.message)
            render :action => 'new'
          when ::OpenID::Consumer::SETUP_NEEDED
            flash[:error] = t(:immediate_request_failed)
            render :action => 'new'
          when ::OpenID::Consumer::CANCEL
            flash[:notice] = t(:transaction_cancelled)
            render :action => 'new'
          end
        end
      end

      private

      def openid_consumer #:nodoc:
        @openid_consumer ||= ::OpenID::Consumer.new(session,
                                                    OpenIdActiveRecordStore.new)
      end
    end
    Openid = OpenID
  end
end
