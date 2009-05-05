class Admission < ActiveRecord::Base
  attr_writer :accepted
  before_save :accepted

  attr_protected :candidate_id, :candidate_type, :candidate 
  attr_protected :group_id, :group_type, :group

  belongs_to :candidate, :polymorphic => true
  belongs_to :group, :polymorphic => true
  belongs_to :introducer, :polymorphic => true
  belongs_to :role

  acts_as_sortable :columns => [ :candidate,
                                 :email,
                                 :group,
                                 :role ]
  named_scope :pending, lambda { 
    { :conditions => { :accepted_at => nil } }
  }

  # Has this Admission been accepted?
  def accepted?
    accepted_at.present?
  end

  # Has this Admission been recently accepted? (typically in this request)
  def recently_accepted?
    @accepted.present?
  end

  private

  def accepted
    return unless @accepted

    to_performance!

    self.accepted_at = Time.now.utc
  end

  def to_performance!
    return unless group && role

    Performance.create! :agent => candidate,
                        :stage => group,
                        :role  => role
  end
end
