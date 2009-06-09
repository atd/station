class Invitation < Admission
  before_validation :find_candidate
  before_create :generate_code

  def to_param
    code
  end

  private

  def find_candidate #:nodoc:
    self.candidate = ActiveRecord::Agent::Invite.find_all(email).first
  end

  def generate_code #:nodoc:
    self.code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end
end
