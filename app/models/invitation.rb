class Invitation < ActiveRecord::Base
  belongs_to :agent, :polymorphic => true
  belongs_to :stage, :polymorphic => true
  belongs_to :role

  validates_presence_of :email, :agent_id, :agent_type

  before_create :make_acceptation_code

  acts_as_sortable :columns => [ :email,
                                 { :name => I18n.t('stage.one'),
                                   :content => proc { |helper, i|
    i.stage ?
      helper.link_to(i.stage.name, helper.polymorphic_path(i.stage)) :
      ""
                                   },
                                   :no_sort => true },
                                 { :name => I18n.t('role.one'),
                                   :content => proc { |helper, i|
    i.role ?
      helper.link_to(i.role.name, helper.polymorphic_path(i.role)) :
      ""
                                   },
                                   :no_sort => true },
                                 { :name => I18n.t('agent.one'),
                                   :content => proc { |helper, i|
    i.agent ?
      helper.link_to(i.agent.name, helper.polymorphic_path(i.agent)) :
      ""
                                   },
                                   :no_sort => true } ]

  def to_performance!
    return unless stage && role

    CMS::ActiveRecord::Agent::Invite.find_all(email).each do |invited_agent|
      Performance.create! :agent => invited_agent,
                          :stage => stage,
                          :role  => role
    end
  end

  def accept!
    to_performance!

    self.accepted_at = Time.now.utc
    self.acceptation_code = nil
    save(false)
  end

  def accepted?
    acceptation_code.nil?
  end

  private

  def make_acceptation_code #:nodoc:
    self.acceptation_code = Digest::SHA1.hexdigest( Time.now.to_s.split(//).sort_by {rand}.join )
  end
end
