class DigitalTwinLog < ApplicationRecord
  belongs_to :digital_twin
  belongs_to :user

  validates :trigger_source, presence: true
  validates :status, inclusion: { in: %w[executed blocked_by_guardrail error] }

  scope :recent, -> { order(created_at: :desc) }
end
