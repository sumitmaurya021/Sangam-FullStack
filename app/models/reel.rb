class Reel < ApplicationRecord
  belongs_to :user
  has_one_attached :video
  has_one_attached :thumbnail
  has_one_attached :music_file

  has_many :reel_likes,    dependent: :destroy
  has_many :likers,        through: :reel_likes, source: :user
  has_many :reel_comments, dependent: :destroy
  has_many :bookmarks,     as: :bookmarkable, dependent: :destroy
  has_many :bookmarked_by, through: :bookmarks, source: :user

  validates :user, presence: true
  validate :acceptable_video

  # Hashtags stored as comma-separated string, exposed as array
  def hashtag_list
    return [] if hashtags.blank?
    hashtags.split(',').map(&:strip).reject(&:empty?)
  end

  def hashtag_list=(arr)
    self.hashtags = Array(arr).map(&:strip).reject(&:empty?).join(',')
  end
  validate :acceptable_music

  scope :recent, -> { order(created_at: :desc) }
  scope :with_associations, -> { includes(:user, :reel_likes, :reel_comments) }

  def liked_by?(user)
    reel_likes.exists?(user_id: user.id)
  end

  def bookmarked_by?(user)
    bookmarks.exists?(user_id: user.id)
  end

  def increment_views!
    increment!(:views_count)
  end

  def hashtag_list
    return [] if hashtags.blank?
    hashtags.scan(/#\w+/).map { |tag| tag.downcase }
  end

  private

  def acceptable_video
    return unless video.attached?

    unless video.content_type.in?(%w[video/mp4 video/webm video/quicktime video/x-msvideo video/mpeg])
      errors.add(:video, 'must be a MP4, WebM, MOV, AVI, or MPEG video')
    end

    if video.byte_size > 200.megabytes
      errors.add(:video, 'should be less than 200MB')
    end
  end

  def acceptable_music
    return unless music_file.attached?

    unless music_file.content_type.in?(%w[audio/mpeg audio/mp3 audio/wav audio/ogg audio/aac])
      errors.add(:music_file, 'must be an MP3, WAV, OGG, or AAC audio file')
    end

    if music_file.byte_size > 10.megabytes
      errors.add(:music_file, 'should be less than 10MB')
    end
  end
end
