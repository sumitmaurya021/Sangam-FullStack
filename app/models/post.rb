class Post < ApplicationRecord
  belongs_to :user
  has_one_attached :image
  has_many :likes, dependent: :destroy
  has_many :likers, through: :likes, source: :user
  has_many :comments, dependent: :destroy
  has_many :shares, dependent: :destroy

  validates :content, presence: true, length: { maximum: 5000 }
  validates :user, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :with_associations, -> { includes(:user, :likes, :comments, :shares) }

  def liked_by?(user)
    likes.exists?(user_id: user.id)
  end
end
