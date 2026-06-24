class Post < ApplicationRecord
  belongs_to :user
  belongs_to :group, optional: true
  has_one_attached :image
  has_many_attached :images  # Multiple images support
  has_many :likes, dependent: :destroy
  has_many :likers, through: :likes, source: :user
  has_many :comments, dependent: :destroy
  has_many :shares, dependent: :destroy
  has_many :bookmarks, as: :bookmarkable, dependent: :destroy
  has_many :bookmarked_by, through: :bookmarks, source: :user
  has_many :post_hashtags, dependent: :destroy
  has_many :hashtags, through: :post_hashtags
  has_many :post_mentions, dependent: :destroy
  has_many :mentioned_users, through: :post_mentions, source: :user
  has_many :post_category_tags, dependent: :destroy
  has_many :category_tags, through: :post_category_tags
  has_one  :poll, dependent: :destroy
  has_one  :fundraiser, dependent: :destroy
  has_many :post_collaborators, dependent: :destroy
  has_many :collaborators, through: :post_collaborators, source: :user
  accepts_nested_attributes_for :poll, reject_if: :poll_blank?, allow_destroy: false
  accepts_nested_attributes_for :fundraiser, reject_if: :fundraiser_blank?, allow_destroy: false

  VISIBILITY_OPTIONS = %w[public friends private close_friends].freeze

  validates :content,    length: { maximum: 5000 }, allow_blank: true
  validates :user,       presence: true
  validates :visibility, inclusion: { in: VISIBILITY_OPTIONS }
  validate  :content_or_poll_present
  validate  :acceptable_images

  scope :published,   -> { where(published: true).where('scheduled_at IS NULL OR scheduled_at <= ?', Time.current) }
  scope :scheduled,   -> { where(published: false).where('scheduled_at > ?', Time.current) }
  scope :recent, -> { order(created_at: :desc) }
  scope :public_posts,   -> { published.where(visibility: 'public') }
  scope :friends_posts,  -> { where(visibility: %w[public friends]) }
  scope :visible_to, ->(user) {
    friend_ids = user.all_friends.pluck(:id)
    close_friend_ids = user.close_friend_records.pluck(:close_friend_id)
    all_ids = (friend_ids + [user.id]).uniq

    if all_ids.any?
      where(
        "posts.visibility = 'public' " \
        "OR posts.user_id = ? " \
        "OR (posts.visibility = 'friends' AND posts.user_id IN (?)) " \
        "OR (posts.visibility = 'close_friends' AND posts.user_id IN (?))",
        user.id, friend_ids, close_friend_ids
      )
    else
      where("posts.visibility = 'public' OR posts.user_id = ?", user.id)
    end
  }
  scope :with_associations, -> { includes(:user, :likes, :comments, :shares, :hashtags) }

  # Feed algorithm: friends-first, then recency, with engagement boost
  # Returns posts ordered by a composite score (friends content = +100 boost)
  scope :ranked_feed, ->(user) {
    friend_ids       = user.all_friends.pluck(:id)
    close_friend_ids = user.close_friend_records.pluck(:close_friend_id)
    all_ids          = (friend_ids + [user.id]).uniq
    friend_ids_sql   = all_ids.any? ? all_ids.join(',') : '0'
    close_ids_sql    = close_friend_ids.any? ? close_friend_ids.join(',') : '0'

    published
      .where(
        "posts.visibility = 'public' " \
        "OR posts.user_id = ? " \
        "OR (posts.visibility = 'friends' AND posts.user_id IN (#{friend_ids_sql})) " \
        "OR (posts.visibility = 'close_friends' AND posts.user_id IN (#{close_ids_sql}))",
        user.id
      )
      .includes(:user, :likes, :comments, :shares, :hashtags)
      .order(
        Arel.sql(
          "(CASE WHEN posts.user_id IN (#{friend_ids_sql}) THEN 100 ELSE 0 END " \
          "+ EXTRACT(EPOCH FROM posts.created_at) / 86400.0 " \
          "+ posts.likes_count * 2 " \
          "+ posts.comments_count * 3) DESC, posts.created_at DESC"
        )
      )
  }
  scope :search, ->(q) { where("content ILIKE ?", "%#{q}%") }

  after_save :process_hashtags
  after_save :process_mentions
  after_commit :enqueue_tag_job, on: [:create, :update]

  def enqueue_tag_job
    TagPostJob.perform_later(self.id)
  end

  def liked_by?(user)
    if likes.loaded?
      likes.any? { |like| like.user_id == user.id }
    else
      likes.exists?(user_id: user.id)
    end
  end
  
  def user_reaction(user)
    if likes.loaded?
      likes.detect { |like| like.user_id == user.id }
    else
      likes.find_by(user_id: user.id)
    end
  end
  
  def reaction_counts
    if likes.loaded?
      likes.each_with_object(Hash.new(0)) { |like, hash| hash[like.reaction_type] += 1 }
    else
      likes.group(:reaction_type).count
    end
  end
  
  def total_images_count
    images.size
  end
  
  def display_images(limit = 5)
    if images.loaded?
      images.take(limit)
    else
      images.limit(limit)
    end
  end
  
  def remaining_images_count
    [total_images_count - 5, 0].max
  end

  def bookmarked_by?(user)
    if bookmarks.loaded?
      bookmarks.any? { |bookmark| bookmark.user_id == user.id }
    else
      bookmarks.exists?(user_id: user.id)
    end
  end

  def edited?
    edited_at.present?
  end

  def has_poll?
    poll.present?
  end

  def has_fundraiser?
    fundraiser.present?
  end

  def scheduled?
    scheduled_at.present? && scheduled_at > Time.current
  end

  def track_view!(user)
    return if user == self.user
    increment!(:views_count)
  end

  def has_link_preview?
    link_url.present? && link_title.present?
  end

  def has_location?
    location_name.present?
  end

  private

  # Poll is blank if question and all options are empty
  def poll_blank?(attrs)
    attrs['question'].blank? &&
      Array(attrs['poll_options_attributes']).all? { |o| o['body'].blank? }
  end

  def fundraiser_blank?(attrs)
    attrs['title'].blank? && attrs['goal_amount'].blank?
  end

  def content_or_poll_present
    return if content.present?
    return if poll.present? || (poll_attributes_present?)
    errors.add(:content, "can't be blank unless you add a poll")
  end

  def poll_attributes_present?
    # During nested attributes build, check if poll will be built
    poll_changed = changes.key?(:id) # new record
    return false
  end

  def process_hashtags
    return unless saved_change_to_content?
    tags = Hashtag.find_or_create_from_text!(content)
    post_hashtags.destroy_all
    tags.each { |tag| post_hashtags.create!(hashtag: tag) }
  rescue => e
    Rails.logger.error "Hashtag processing failed for post #{id}: #{e.message}"
  end

  def process_mentions
    return unless saved_change_to_content?
    mentions = content.scan(/@(\w+)/).flatten.uniq
    return if mentions.empty?

    post_mentions.destroy_all
    mentions.each do |username|
      mentioned_user = User.find_by("name ILIKE ?", username)
      next unless mentioned_user && mentioned_user != user
      post_mentions.create!(user: mentioned_user, mentionable: self)
    end
  rescue => e
    Rails.logger.error "Mention processing failed for post #{id}: #{e.message}"
  end

  def acceptable_images
    return unless images.attached?

    images.each do |image|
      unless image.content_type.in?(%w[image/jpeg image/png image/gif image/webp])
        errors.add(:images, 'must be a JPEG, PNG, GIF, or WebP')
      end

      if image.byte_size > 10.megabytes
        errors.add(:images, 'should be less than 10MB')
      end
    end
  end
end
