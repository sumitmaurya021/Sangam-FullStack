class ReelLike < ApplicationRecord
  belongs_to :user
  belongs_to :reel, counter_cache: :likes_count

  validates :user_id, uniqueness: { scope: :reel_id, message: 'has already liked this reel' }

  after_create :create_notification

  private

  def create_notification
    return if user_id == reel.user_id

    Notification.create!(
      recipient: reel.user,
      actor:     user,
      notifiable: reel,
      notification_type: 'reel_like',
      message: "#{user.name} liked your reel"
    )
  rescue => e
    Rails.logger.error "Notification creation failed for reel_like #{id}: #{e.message}"
  end
end
