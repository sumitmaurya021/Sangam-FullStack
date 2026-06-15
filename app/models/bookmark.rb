class Bookmark < ApplicationRecord
  belongs_to :user
  belongs_to :bookmarkable, polymorphic: true
  belongs_to :bookmark_collection, optional: true

  # Legacy — kept for existing post_id FK rows; optional so reel bookmarks work
  belongs_to :post, optional: true

  validates :bookmarkable_id,
            uniqueness: { scope: [:user_id, :bookmarkable_type],
                          message: 'already bookmarked' }

  scope :recent,          -> { order(created_at: :desc) }
  scope :for_posts,       -> { where(bookmarkable_type: 'Post') }
  scope :for_reels,       -> { where(bookmarkable_type: 'Reel') }
  scope :in_collection,   ->(col_id) { where(bookmark_collection_id: col_id) }
  scope :uncategorized,   -> { where(bookmark_collection_id: nil) }

  # Convenience: build from a polymorphic target
  def self.for(user:, bookmarkable:)
    find_by(user: user, bookmarkable_type: bookmarkable.class.name,
            bookmarkable_id: bookmarkable.id)
  end
end
