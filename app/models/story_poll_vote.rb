class StoryPollVote < ApplicationRecord
  belongs_to :story
  belongs_to :user

  validates :option, inclusion: { in: %w[a b] }
  validates :user_id, uniqueness: { scope: :story_id, message: 'already voted' }

  after_create :increment_vote_count

  private

  def increment_vote_count
    column = option == 'a' ? :poll_votes_a : :poll_votes_b
    story.increment!(column)
  end
end
