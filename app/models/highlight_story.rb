class HighlightStory < ApplicationRecord
  belongs_to :profile_highlight
  belongs_to :story

  validates :profile_highlight_id, uniqueness: { scope: :story_id }
end
