class PollOption < ApplicationRecord
  belongs_to :poll
  has_many   :poll_votes, dependent: :destroy

  validates :body,     presence: true, length: { maximum: 100 }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def percentage
    total = poll.total_votes
    return 0 if total.zero?
    ((votes_count.to_f / total) * 100).round(1)
  end
end
