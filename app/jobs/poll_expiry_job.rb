# Expires a single poll when its ends_at time is reached.
# Enqueued at poll creation: PollExpiryJob.set(wait_until: poll.ends_at).perform_later(poll.id)
class PollExpiryJob < ApplicationJob
  queue_as :default

  # Discard silently if the poll was deleted before the job ran
  discard_on ActiveRecord::RecordNotFound

  def perform(poll_id)
    poll = Poll.find(poll_id)
    return if poll.expired?            # already expired (e.g. manual action)
    return unless poll.ends_at.present? && poll.ends_at <= Time.current

    poll.expire!
    Rails.logger.info "PollExpiryJob: poll ##{poll_id} expired."
  end
end
