class Admission < ActiveRecord::Base
  validates_uniqueness_of :candidate_id,   :scope => [ :candidate_type, :group_id, :group_type ]
  validates_uniqueness_of :candidate_type, :scope => [ :candidate_id,   :group_id, :group_type ]
  validates_uniqueness_of :email, :scope => [ :group_id, :group_type ]

  before_validation :fill_candidate_email

  attr_writer :processed
  before_save :processed

  after_save :to_performance!

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
    { :conditions => { :processed_at => nil } }
  }

  # Has this Admission been processed?
  def processed?
    processed_at.present?
  end

  # Has this Admission been recently processed? (typically in this request)
  def recently_processed?
    @processed.present?
  end

  private

  def fill_candidate_email
    if email.blank? && candidate && candidate.respond_to?(:email)
      self.email = candidate.email
    end
  end

  def processed
    @processed && self.processed_at = Time.now.utc
  end

  def to_performance!
    return unless recently_processed? && accepted? && group && role

    Performance.create! :agent => candidate,
                        :stage => group,
                        :role  => role
  end
end
