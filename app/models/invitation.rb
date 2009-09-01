class Invitation < Admission
  validates_presence_of :email
  validate :valid_role

  before_create :generate_code

  def to_param
    code
  end

  private

  def generate_code #:nodoc:
    self.code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end

  def valid_role
    return if role.blank?

    introducer_role = group.role_for(introducer)
    return if introducer_role.blank?

    if role > introducer_role
      errors.add(:role, :less_than_or_equal_to, :count => introducer_role)
    end
  end
end
