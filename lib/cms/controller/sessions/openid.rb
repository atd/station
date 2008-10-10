require 'openid'
require 'openid/extensions/sreg'

module CMS
  module Controller
    module Sessions
      # OpenID sessions management
      module OpenID
        # Create new Session using OpenID
        def create_with_openid
          if !params[:openid_identifier].blank?
            begin
              openid_request = openid_consumer.begin params[:openid_identifier]
            rescue ::OpenID::OpenIDError => e
              flash[:error] = "Discovery failed for %s: %s" / [ params[:openid_identifier], e ]
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
              flash[:notice] = "Verification of %s succeeded" / openid_response.display_identifier
              uri = Uri.find_or_create_by_uri(openid_response.display_identifier)

              CMS::Agent.authentication_classes(:openid).each do |klass|
                self.current_agent = 
                  klass.authenticate_with_openid(uri)
                break if authenticated?
              end

              if authenticated?
                redirect_back_or_default after_create_path
                flash[:notice] = "Logged in successfully".t
              else
                # TODO if already authenticated, add URI to Agent.openid_ownings
                # else
                # We create new OpenidUser
                session[:openid_identifier] = openid_response.display_identifier
                sreg_response = ::OpenID::SReg::Response.from_success_response(openid_response)
                render_component :controller => CMS::Agent.authentication_classes(:openid).first.to_s.tableize,
                                 :action => "create",
                                 :params => { :openid_user => sreg_response.data }
              end
            when ::OpenID::Consumer::FAILURE
              flash[:error] = openid_response.display_identifier ?
                "Verification of %s failed: %s" / [ openid_response.display_identifier, openid_response.message ] :
                "Verification failed: %s" / openid_response.message
              render :action => 'new'
            when ::OpenID::Consumer::SETUP_NEEDED
              flash[:error] = "Immediate request failed - Setup Needed".t
              render :action => 'new'
            when ::OpenID::Consumer::CANCEL
              flash[:notice] = "OpenID transaction cancelled".t
              render :action => 'new'
            end
          end
        end

        private

        def openid_consumer #:nodoc:
          @openid_consumer ||= ::OpenID::Consumer.new(session,
                                                      CMS::OpenID::ActiveRecordStore.new)
        end
      end
      Openid = OpenID
    end
  end
end
