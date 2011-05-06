# == Schema Information
# Schema version: 20100227074439
#
# Table name: pending_community_users
#
#  id             :integer         not null, primary key
#  user_id        :integer
#  community_id   :integer
#  apply_message  :text
#  reject_message :text
#  state          :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#

class PendingCommunityUser < ActiveRecord::Base
  include AASM

  belongs_to :community
  belongs_to :user
  belongs_to :judge, :foreign_key => "judge_id", :class_name => "User"

  aasm_column :state

  aasm_initial_state Proc.new { |membership|
    membership.community.approval_required? ? :pending : :active
  }

  # コミュニティへの参加申請を行った初期状態
  aasm_state :pending

  # 管理人・及び副管理人に招待された状態
  aasm_state :invited

  # コミュニティへの参加が許可された状態
  aasm_state :active

  # コミュニティへの参加が拒否された状態
  aasm_state :rejected, :enter => :send_reject_mail_and_message

  aasm_event :activate do
    transitions :to => :active, :from => :pending, :on_transition => :participate
  end

  aasm_event :activate_from_invited do
    transitions :to => :active, :from => :invited
  end

  aasm_event :reject do
    transitions :to => :rejected, :from => :pending
  end

  named_scope :by_pending_user, lambda{ |user| { :conditions => ["user_id = ? AND state = 'pending'", user.id] }}

  named_scope :by_community, lambda{ |community| { :conditions => ["community_id = ?", community.id] }}

  named_scope :pending_only, lambda{ { :conditions => "state = 'pending'"} }

  named_scope :by_invited_user, lambda{ |user| { :conditions => ["user_id = ? AND state = 'invited'", user.id] }}

  # 参加をしたときの処理
  # 参加者へメールが送信される。
  # また、メッセージも作成する
  def participate
    CommunityMembership.create!(:user_id => self.user_id,
                                :community_id => self.community_id)
    self.user.has_role!(:community_general, self.community)
    mail = CommunityApprovalNotifier.create_acceptance(self)
    message = Message.new(Message.default_attributes({:body => NKF::nkf("-w8", mail.body),
                                                       :receiver_id => self.user.id,
                                                       :subject => "コミュニティへ参加が承認されました"},
                                                       self.judge))

    message.save!
    CommunityApprovalNotifier.deliver(mail)
  end

  # 参加拒否したときに、メッセージがあればメールを送信する
  # また、メッセージも作成する
  def send_reject_mail_and_message
    unless self.reject_message.blank?
      mail = CommunityApprovalNotifier.create_rejection(self)
      message = Message.new(Message.default_attributes({:body => NKF::nkf("-w8", mail.body),
                                                         :receiver_id => self.user.id,
                                                         :subject => "コミュニティへ参加が承認されませんでした"},
                                                       self.judge))

      message.save!
      CommunityApprovalNotifier.deliver(mail)
    end
  end
end
