class EventResponse < ApplicationRecord
  belongs_to :event
  belongs_to :user

  RESPONSES = %w[going interested not_going].freeze

  validates :response, inclusion: { in: RESPONSES }
  validates :user_id, uniqueness: { scope: :event_id }

  after_save    :sync_event_counters
  after_destroy :sync_event_counters

  private

  def sync_event_counters
    event.update_columns(
      going_count:      event.event_responses.where(response: 'going').count,
      interested_count: event.event_responses.where(response: 'interested').count
    )
  end
end
