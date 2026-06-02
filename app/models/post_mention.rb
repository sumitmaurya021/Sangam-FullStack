class PostMention < ApplicationRecord
  belongs_to :post
  belongs_to :user

  # mentionable is the Post or Comment the mention appears in
  belongs_to :mentionable, polymorphic: true, optional: true

  validates :user_id, uniqueness: { scope: :post_id }

  after_create :notify_mentioned_user

  private

  def notify_mentioned_user
    return if user_id == post.user_id  # don't notify yourself

    n = Notification.create!(
      recipient:         user,
      actor:             post.user,
      notifiable:        post,
      notification_type: 'mention',
      message:           "#{post.user.name} mentioned you in a post"
    )
    n.broadcast_to_recipient
  rescue => e
    Rails.logger.error "PostMention notification failed: #{e.message}"
  end
end
