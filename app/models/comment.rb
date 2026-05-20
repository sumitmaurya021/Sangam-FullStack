class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post, counter_cache: :comments_count

  validates :content, presence: true, length: { maximum: 1000 }
  validates :user, presence: true
  validates :post, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
