class Conversation < ApplicationRecord
  belongs_to :sender, class_name: 'User'
  belongs_to :recipient, class_name: 'User'

  has_many :messages, dependent: :destroy
  has_one :latest_message, -> { where(deleted: false).order(created_at: :desc) }, class_name: 'Message'

  # Active Storage for message attachments (accessed via messages)
  validates :sender_id, presence: true
  validates :recipient_id, presence: true
  validate :not_self_conversation

  scope :involving, ->(user) {
    where("sender_id = ? OR recipient_id = ?", user.id, user.id)
  }

  scope :recent, -> { order(last_message_at: :desc, created_at: :desc) }

  # Find or create a conversation between two users
  def self.between(user1, user2)
    where(
      "(sender_id = ? AND recipient_id = ?) OR (sender_id = ? AND recipient_id = ?)",
      user1.id, user2.id, user2.id, user1.id
    ).first
  end

  def self.find_or_create_between(user1, user2)
    between(user1, user2) || create!(sender: user1, recipient: user2)
  end

  # Get the other participant in the conversation
  def other_participant(current_user)
    sender_id == current_user.id ? recipient : sender
  end

  # Count unread messages for a specific user
  def unread_count_for(user)
    messages.where.not(user_id: user.id).where(read_at: nil).where(deleted: false).count
  end

  # Mark all messages as read for a user
  def mark_as_read_for!(user)
    messages.where.not(user_id: user.id).where(read_at: nil).update_all(read_at: Time.current)
  end

  # Last message in conversation
  def last_message
    messages.where(deleted: false).order(created_at: :desc).first
  end

  private

  def not_self_conversation
    errors.add(:base, "Cannot have a conversation with yourself") if sender_id == recipient_id
  end
end
