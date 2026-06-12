class GroupChat < ApplicationRecord
  belongs_to :owner, class_name: 'User'
  has_one_attached :avatar

  has_many :group_chat_members, dependent: :destroy
  has_many :members, through: :group_chat_members, source: :user
  has_many :group_chat_messages, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }

  after_create :add_owner_as_admin

  # ── Scopes ─────────────────────────────────────────────────────────────────
  scope :for_user, ->(user) {
    joins(:group_chat_members).where(group_chat_members: { user_id: user.id })
  }
  scope :recent_activity, -> { order(updated_at: :desc) }

  # ── Membership helpers ──────────────────────────────────────────────────────
  def member?(user)
    group_chat_members.exists?(user_id: user.id)
  end

  def admin?(user)
    group_chat_members.exists?(user_id: user.id, role: 'admin')
  end

  def add_member!(user, role: 'member')
    gcm = group_chat_members.find_or_create_by!(user: user) do |m|
      m.role = role
    end
    # Only increment counter when a new record was actually inserted
    increment!(:members_count) if gcm.previously_new_record?
    gcm
  rescue ActiveRecord::RecordNotUnique
    # Race-condition safety — already a member, nothing to do
  end

  def remove_member!(user)
    gcm = group_chat_members.find_by(user: user)
    return unless gcm
    gcm.destroy
    decrement!(:members_count)
  end

  # Last message for sidebar preview
  def last_message
    group_chat_messages.where(deleted: false).order(created_at: :desc).first
  end

  # Unread count for a given user (messages not sent by them, after their
  # last read — simplified: all non-deleted messages not sent by user)
  def unread_count_for(user)
    group_chat_messages.where.not(user: user).where(deleted: false).count
  end

  private

  def add_owner_as_admin
    group_chat_members.create!(user: owner, role: 'admin')
    update_column(:members_count, 1)
  end
end
