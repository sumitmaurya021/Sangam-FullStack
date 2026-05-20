class Share < ApplicationRecord
  belongs_to :user
  belongs_to :post, counter_cache: :shares_count

  validates :user_id, uniqueness: { scope: :post_id, message: "has already shared this post" }
end
