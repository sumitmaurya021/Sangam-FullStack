class BookmarkCollection < ApplicationRecord
  belongs_to :user
  has_many   :bookmarks, foreign_key: :bookmark_collection_id, dependent: :nullify

  validates :name, presence: true, length: { maximum: 50 }
  validates :name, uniqueness: { scope: :user_id, message: 'already exists' }

  scope :ordered, -> { order(created_at: :asc) }

  DEFAULT_NAME = 'All Saved'.freeze

  def self.default_for(user)
    find_or_create_by!(user: user, is_default: true) do |c|
      c.name = DEFAULT_NAME
    end
  end

  def cover_thumbnail_url(routes)
    bm = bookmarks.includes(:bookmarkable).first
    return nil unless bm&.bookmarkable
    bookmarkable = bm.bookmarkable
    case bookmarkable
    when Post
      if bookmarkable.images.attached?
        routes.rails_blob_path(bookmarkable.images.first, only_path: true) rescue nil
      elsif bookmarkable.image.attached?
        routes.rails_blob_path(bookmarkable.image, only_path: true) rescue nil
      end
    when Reel
      if bookmarkable.thumbnail.attached?
        routes.rails_blob_path(bookmarkable.thumbnail, only_path: true) rescue nil
      end
    end
  end

  def bookmarks_count
    bookmarks.count
  end
end
