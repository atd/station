class Invitation < Admission
  before_create :set_candidate
  before_create :set_code

  def to_param
    code
  end

  private

  def set_candidate #:nodoc:
    self.candidate = ActiveRecord::Agent::Invite.find_all(email).first
  end

  def set_code #:nodoc:
    self.code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end
end
