class ReelComment < ApplicationRecord
  belongs_to :user
  belongs_to :reel, counter_cache: :comments_count
  belongs_to :parent, class_name: 'ReelComment', optional: true
  has_many :replies, class_name: 'ReelComment', foreign_key: :parent_id, dependent: :destroy

  validates :content, presence: true, length: { maximum: 2000 }
  validates :user, presence: true

  scope :root_comments, -> { where(parent_id: nil) }
  scope :recent, -> { order(created_at: :asc) }

  after_create :notify_reel_owner

  private

  def notify_reel_owner
    return if user_id == reel.user_id

    Notification.create!(
      recipient: reel.user,
      actor:     user,
      notifiable: reel,
      notification_type: 'reel_comment',
      message: "#{user.name} commented on your reel"
    )
  rescue => e
    Rails.logger.error "Notification creation failed for reel_comment #{id}: #{e.message}"
  end
end
