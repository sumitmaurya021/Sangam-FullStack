class Share < ApplicationRecord
  belongs_to :user
  belongs_to :post, counter_cache: :shares_count

  validates :user_id, uniqueness: { scope: :post_id, message: "has already shared this post" }

  after_create :create_notification

  private

  def create_notification
    return if user_id == post.user_id

    n = Notification.create!(
      recipient: post.user,
      actor: user,
      notifiable: post,
      notification_type: 'share',
      message: "#{user.name} shared your post"
    )
    n.broadcast_to_recipient
  rescue => e
    Rails.logger.error "Notification failed for share #{id}: #{e.message}"
  end
end
