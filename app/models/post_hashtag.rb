class PostHashtag < ApplicationRecord
  belongs_to :post
  belongs_to :hashtag, counter_cache: :posts_count

  validates :hashtag_id, uniqueness: { scope: :post_id }
end
