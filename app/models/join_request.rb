class JoinRequest < Admission
  validates_presence_of :candidate_id, :candidate_type
  validates_uniqueness_of :candidate_id, :candidate_type, :scope => [ :group_id, :group_type ]

end
