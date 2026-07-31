class AiModerationLog < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :target, polymorphic: true, optional: true

  validates :action_taken, inclusion: { in: %w[approved blocked flagged_for_review] }

  scope :recent, -> { order(created_at: :desc) }
  scope :flagged, -> { where(action_taken: %w[blocked flagged_for_review]) }
  scope :blocked, -> { where(action_taken: "blocked") }
  scope :for_review, -> { where(action_taken: "flagged_for_review") }
end
