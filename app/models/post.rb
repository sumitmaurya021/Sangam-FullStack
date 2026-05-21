class Post < ApplicationRecord
  belongs_to :user
  has_one_attached :image
  has_many_attached :images  # Multiple images support
  has_many :likes, dependent: :destroy
  has_many :likers, through: :likes, source: :user
  has_many :comments, dependent: :destroy
  has_many :shares, dependent: :destroy

  validates :content, presence: true, length: { maximum: 5000 }
  validates :user, presence: true
  validate :acceptable_images

  scope :recent, -> { order(created_at: :desc) }
  scope :with_associations, -> { includes(:user, :likes, :comments, :shares) }

  def liked_by?(user)
    likes.exists?(user_id: user.id)
  end
  
  def user_reaction(user)
    likes.find_by(user_id: user.id)
  end
  
  def reaction_counts
    likes.group(:reaction_type).count
  end
  
  def total_images_count
    images.count
  end
  
  def display_images(limit = 5)
    images.limit(limit)
  end
  
  def remaining_images_count
    [total_images_count - 5, 0].max
  end

  private

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
