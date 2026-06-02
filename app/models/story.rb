class Story < ApplicationRecord
  belongs_to :user
  has_one_attached :media   # image or video file
  has_many :story_views, dependent: :destroy
  has_many :viewers, through: :story_views, source: :user

  STORY_TYPES = %w[image video text].freeze

  validates :story_type, inclusion: { in: STORY_TYPES }
  validates :expires_at, presence: true
  validate  :acceptable_media

  scope :active,   -> { where('expires_at > ?', Time.current) }
  scope :expired,  -> { where('expires_at <= ?', Time.current) }
  scope :recent,   -> { order(created_at: :desc) }

  before_validation :set_expiry, on: :create

  def active?
    expires_at > Time.current
  end

  def viewed_by?(user)
    story_views.exists?(user_id: user.id)
  end

  def mark_viewed_by!(user)
    return if viewed_by?(user) || user == self.user
    story_views.create!(user: user)
    increment!(:views_count)
  end

  def time_remaining
    ((expires_at - Time.current) / 3600).round(1)
  end

  private

  def set_expiry
    self.expires_at ||= 24.hours.from_now
  end

  def acceptable_media
    return unless media.attached?

    if story_type == 'video'
      unless media.content_type.in?(%w[video/mp4 video/webm video/quicktime])
        errors.add(:media, 'must be MP4, WebM, or MOV')
      end
      errors.add(:media, 'should be less than 50MB') if media.byte_size > 50.megabytes
    else
      unless media.content_type.in?(%w[image/jpeg image/png image/gif image/webp])
        errors.add(:media, 'must be JPEG, PNG, GIF, or WebP')
      end
      errors.add(:media, 'should be less than 10MB') if media.byte_size > 10.megabytes
    end
  end
end
