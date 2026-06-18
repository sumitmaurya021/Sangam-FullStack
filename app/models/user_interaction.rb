class UserInteraction < ApplicationRecord
  belongs_to :user
  belongs_to :post

  enum :interaction_type, {
    impression: 0,
    dwell: 1,
    like: 2,
    comment: 3,
    save_post: 4,
    share: 5,
    follow: 6,
    hide: 7
  }

  after_create :bump_affinities

  private

  def bump_affinities
    # Define weights
    weights = {
      "impression" => 1,
      "dwell" => 2,
      "like" => 3,
      "comment" => 5,
      "save_post" => 6,
      "share" => 7,
      "follow" => 4,
      "hide" => -8
    }

    weight = weights[self.interaction_type] || 1

    # For each tag on the post, bump the user's affinity
    post.post_category_tags.each do |pct|
      affinity = UserTagAffinity.find_or_create_by!(user: user, category_tag: pct.category_tag) do |uta|
        uta.score = 0.0
      end
      affinity.score += (weight * pct.confidence_score)
      affinity.save!
    end
  end
end
