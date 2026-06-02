class Bookmark < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :post_id, uniqueness: { scope: :user_id }

  scope :recent, -> { order(created_at: :desc) }
end
