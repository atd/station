class InvitationsController < ApplicationController
  before_filter :invitation, :only => [ :show, :update, :delete ]
  before_filter :candidate_authenticated, :only => [ :show, :update ]

  # GET /invitations
  # GET /invitations.xml
  def index
    @invitations = group ?
      group.invitations.column_sort(params[:order], params[:direction]) :
      Invitation.column_sort(params[:order], params[:direction])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @invitations }
    end
  end

  # GET /invitations/1
  # GET /invitations/1.xml
  def show
    unless @invitation
      flash[:error] = t('invitation.not_found')
      redirect_to root_path
      return
    end

    respond_to do |format|
      format.html {
        if @invitation.processed?
          flash[:notice] = t(@invitation.state, :scope => 'invitation.was_processed')
          redirect_to @invitation.group
        else
          @candidate = ActiveRecord::Agent::Invite.classes.first.new
        end
      }
      format.xml  { render :xml => @invitation }
    end
  end

  def create
    @invitation = ( group.try(:invitations) || Invitation ).new params[:invitation]
    @invitation.introducer = current_agent

    if @invitation.save
      flash[:success] = t('invitation.created')
    else
      flash[:error] = @invitation.errors.to_xml
    end

    redirect_to(request.referer || [ group, Invitation.new ])
  end

  # PUT /invitations/1
  # PUT /invitations/1.xml
  def update
    unless authenticated?
      # To update an Invitation, we require always Authentication.
      #
      # The agent may register or signup with her account, due to other email.
      klass = ActiveRecord::Agent::Invite.classes.first

      # We first try to authenticate the credentials
      # TODO: other authentication methods like OpenID
      @candidate = params[klass.to_s.underscore].present? ?
        klass.authenticate_with_login_and_password(params[klass.to_s.underscore][:login],
                                                   params[klass.to_s.underscore][:password]) :
        nil

      if @candidate.blank?
        # If agent is not authenticated, try to register
        @candidate = klass.new(params[klass.to_s.underscore])
        @candidate.email = invitation.email
        # Agent has read the invitation email, so it's already activated
        @candidate.activated_at = Time.now if @candidate.agent_options[:activation]
        
        unless @candidate.save
          render :action => :show
          return
        end
      end

      # Authenticate Agent
      self.current_agent = @candidate

      # invitation.candidate should have changed, explicity or due to current_agent callback
      invitation.reload
    end


    invitation.attributes = params[:invitation]
    # Invitation may be accepted by an already registered user when sent to a different
    # email address
    invitation.candidate ||= current_agent if params[:invitation][:processed]

    respond_to do |format|
      if invitation.save
        format.html {
          flash[:success] = invitation.state_message
          redirect_to(invitation.group || root_path)
        }
      else
        format.html { render :action => :show }
      end
    end
  end

  # DELETE /invitations/1
  # DELETE /invitations/1.xml
  def destroy
    invitation.destroy

    respond_to do |format|
      format.html { redirect_to(request.referer || [ invitation.group, Invitation.new ]) }
      format.xml  { head :ok }
    end
  end

  private

  def group
    @group ||= record_from_path(:acts_as => :stage)
  end

  def invitation
    @invitation ||= Invitation.find_by_code(params[:id]) || raise(ActiveRecord::RecordNotFound, "Invitation not found")
  end

  def candidate_authenticated
    not_authenticated if invitation.candidate && ! authenticated?
  end
end
