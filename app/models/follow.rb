class Follow < ApplicationRecord
  belongs_to :follower, class_name: 'User', counter_cache: :following_count
  belongs_to :followee, class_name: 'User', counter_cache: :followers_count

  validates :follower_id, uniqueness: { scope: :followee_id, message: 'already following' }
  validate :cannot_follow_self

  after_create  :notify_followee
  after_destroy :broadcast_unfollow

  private

  def cannot_follow_self
    errors.add(:followee_id, "can't follow yourself") if follower_id == followee_id
  end

  # Notify the person being followed
  def notify_followee
    n = Notification.create!(
      recipient: followee,
      actor:     follower,
      notifiable: self,
      notification_type: 'follow',
      message: "#{follower.name} started following you"
    )
    n.broadcast_to_recipient
  rescue => e
    Rails.logger.error "Follow notification failed for follow #{id}: #{e.message}"
  end

  # Broadcast unfollow so follow button updates in other tabs (optional)
  def broadcast_unfollow
    # No-op for now; button state is managed client-side via Turbo Stream
  end
end
