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
        @candidate = ActiveRecord::Agent::Invite.classes.first.new
      }
      format.xml  { render :xml => @invitation }
    end
  end

  # PUT /invitations/1
  # PUT /invitations/1.xml
  def update
    unless invitation.candidate
      klass = ActiveRecord::Agent::Invite.classes.first
      @candidate = klass.new(params[klass.to_s.underscore])
      @candidate.email = invitation.email
      # Agent has read the invitation email, so it's already activated
      @candidate.activated_at = Time.now if @candidate.agent_options[:activation]
      
      unless @candidate.save
        render :action => :show
        return
      end

      # Authenticate Agent
      self.current_agent = @candidate

      # invitation.candidate should have changed, due to current_agent callback
      invitation.reload
    end

    respond_to do |format|
      if invitation.update_attributes(params[:invitation])
        format.html {
          format[:notice] = t('invitation.accepted', :group => invitation.group.name) if invitation.recently_accepted?
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
      format.html { redirect_to [ @invitation.group, Admission.new ] }
      format.xml  { head :ok }
    end
  end

  private

  def group
    @group ||= record_from_path(:acts_as => :group)
  end

  def invitation
    @invitation ||= Invitation.find_by_code(params[:id])
  end

  def candidate_authenticated
    not_authenticated if invitation.candidate && ! authenticated?
  end
end
