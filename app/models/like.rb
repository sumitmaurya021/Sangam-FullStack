class Like < ApplicationRecord
  belongs_to :user
  belongs_to :post, counter_cache: :likes_count

  validates :user_id, uniqueness: { scope: :post_id, message: "has already liked this post" }
  validates :reaction_type, inclusion: { in: %w[like love haha wow sad angry], message: "%{value} is not a valid reaction" }
  
  # Reaction types
  REACTIONS = {
    'like' => '👍',
    'love' => '❤️',
    'haha' => '😆',
    'wow' => '😮',
    'sad' => '😢',
    'angry' => '😠'
  }.freeze
  
  def reaction_emoji
    REACTIONS[reaction_type]
  end
end
