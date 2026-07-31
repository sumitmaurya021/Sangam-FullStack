class UxTelemetryEvent < ApplicationRecord
  belongs_to :user, optional: true

  validates :page_route, presence: true
  validates :event_type, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :friction_events, -> { where(event_type: %w[form_abandonment field_hesitation rapid_backtrack]) }
end
