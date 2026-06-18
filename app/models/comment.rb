class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post, counter_cache: :comments_count

  # Nested comments support (Instagram-style flat replies)
  belongs_to :parent, class_name: 'Comment', optional: true, counter_cache: :replies_count
  has_many :replies, class_name: 'Comment', foreign_key: :parent_id, dependent: :destroy

  # Voice Notes
  has_one_attached :attachment

  # Who this reply is directed at (for @mention display)
  belongs_to :replied_to_user, class_name: 'User', optional: true

  validates :content, presence: true, length: { maximum: 1000 }, unless: -> { attachment.attached? }
  validates :user, presence: true
  validates :post, presence: true

  scope :recent, -> { order(created_at: :asc) }
  scope :top_level, -> { where(parent_id: nil) }
  scope :with_user, -> { includes(:user) }

  after_create :create_notifications

  def reply?
    parent_id.present?
  end

  def top_level?
    parent_id.nil?
  end

  # Returns the root-level parent (for flat reply grouping)
  def root_parent
    parent&.parent_id.present? ? parent.root_parent : parent
  end

  private

  def create_notifications
    if reply?
      # Notify post owner (if not the commenter)
      if post.user_id != user_id
        n = Notification.create!(
          recipient: post.user,
          actor: user,
          notifiable: self,
          notification_type: 'reply',
          message: "#{user.name} replied to a comment on your post"
        )
        n.broadcast_to_recipient
      end

      # Notify the person being replied to (if different from commenter and post owner)
      if replied_to_user_id.present? && replied_to_user_id != user_id && replied_to_user_id != post.user_id
        n = Notification.create!(
          recipient: replied_to_user,
          actor: user,
          notifiable: self,
          notification_type: 'reply',
          message: "#{user.name} replied to your comment"
        )
        n.broadcast_to_recipient
      end
    else
      # Top-level comment — notify post owner
      return if post.user_id == user_id

      n = Notification.create!(
        recipient: post.user,
        actor: user,
        notifiable: self,
        notification_type: 'comment',
        message: "#{user.name} commented on your post"
      )
      n.broadcast_to_recipient
    end
  rescue => e
    Rails.logger.error "Notification creation failed for comment #{id}: #{e.message}"
  end
end
