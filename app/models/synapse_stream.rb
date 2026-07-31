class SynapseStream < ApplicationRecord
  belongs_to :user

  validates :status, inclusion: { in: %w[draft synthesized published] }

  scope :recent, -> { order(created_at: :desc) }

  # Check if stream has synthesized content available
  def synthesized?
    status == "synthesized" || status == "published"
  end

  # Check if stream has been published to live entities
  def published?
    status == "published"
  end
end
