class Like < ApplicationRecord
  belongs_to :user
  belongs_to :post, counter_cache: :likes_count

  validates :user_id, uniqueness: { scope: :post_id, message: "has already liked this post" }
  validates :reaction_type, inclusion: { in: %w[like love haha wow sad angry], message: "%{value} is not a valid reaction" }
  
  # Reaction types
  REACTIONS = {
    'like' => '👍',
    'love' => '❤️',
    'haha' => '😆',
    'wow' => '😮',
    'sad' => '😢',
    'angry' => '😠'
  }.freeze

  after_create :create_notification

  def reaction_emoji
    REACTIONS[reaction_type]
  end

  private

  def create_notification
    return if user_id == post.user_id

    notification = Notification.create!(
      recipient: post.user,
      actor: user,
      notifiable: post,
      notification_type: 'like',
      message: "#{user.name} reacted #{reaction_emoji} to your post"
    )
    notification.broadcast_to_recipient
  rescue => e
    Rails.logger.error "Notification creation failed for like #{id}: #{e.message}"
  end
end
