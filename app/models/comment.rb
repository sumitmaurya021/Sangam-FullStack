class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post, counter_cache: :comments_count

  # Nested comments support (Instagram-style flat replies)
  belongs_to :parent, class_name: 'Comment', optional: true, counter_cache: :replies_count
  has_many :replies, class_name: 'Comment', foreign_key: :parent_id, dependent: :destroy

  # Who this reply is directed at (for @mention display)
  belongs_to :replied_to_user, class_name: 'User', optional: true

  validates :content, presence: true, length: { maximum: 1000 }
  validates :user, presence: true
  validates :post, presence: true

  scope :recent, -> { order(created_at: :asc) }
  scope :top_level, -> { where(parent_id: nil) }
  scope :with_user, -> { includes(:user) }

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
end
