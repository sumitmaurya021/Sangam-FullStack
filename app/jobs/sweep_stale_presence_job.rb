# Sweeps users who are still marked online but have not sent a heartbeat
# in the last 2 minutes (covers crashed browsers, network drops, etc.)
class SweepStalePresenceJob < ApplicationJob
  queue_as :default

  # Run every minute via solid_queue recurring schedule (see config/recurring.yml)
  STALE_THRESHOLD = 2.minutes

  def perform
    stale = User.where(online: true)
                .where("last_seen_at < ?", STALE_THRESHOLD.ago)

    stale.find_each do |user|
      user.update_columns(online: false)

      ActionCable.server.broadcast(
        "user_presence",
        {
          type:         "presence_update",
          user_id:      user.id,
          online:       false,
          last_seen_at: user.last_seen_at&.iso8601
        }
      )
    end

    Rails.logger.info "SweepStalePresenceJob: marked #{stale.count} users offline." if stale.any?
  end
end
