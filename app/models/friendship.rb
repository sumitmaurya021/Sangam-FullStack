class Friendship < ApplicationRecord
  belongs_to :user
  belongs_to :friend, class_name: 'User'

  validates :user_id, uniqueness: { scope: :friend_id, message: "friendship already exists" }
  validates :status, inclusion: { in: %w[pending accepted rejected] }
  validate :not_self_friendship

  scope :pending, -> { where(status: 'pending') }
  scope :accepted, -> { where(status: 'accepted') }

  after_create :notify_friend_request
  after_update :notify_friend_accepted, if: :status_changed_to_accepted?

  def accept!
    update(status: 'accepted')
  end

  def reject!
    update(status: 'rejected')
  end

  private

  def not_self_friendship
    errors.add(:friend_id, "can't be the same as user") if user_id == friend_id
  end

  def notify_friend_request
    n = Notification.create!(
      recipient: friend,
      actor: user,
      notifiable: self,
      notification_type: 'friend_request',
      message: "#{user.name} sent you a friend request"
    )
    n.broadcast_to_recipient
  rescue => e
    Rails.logger.error "Notification failed for friend_request #{id}: #{e.message}"
  end

  def notify_friend_accepted
    n = Notification.create!(
      recipient: user,
      actor: friend,
      notifiable: self,
      notification_type: 'friend_accepted',
      message: "#{friend.name} accepted your friend request"
    )
    n.broadcast_to_recipient
  rescue => e
    Rails.logger.error "Notification failed for friend_accepted #{id}: #{e.message}"
  end

  def status_changed_to_accepted?
    saved_change_to_status? && status == 'accepted'
  end
end
