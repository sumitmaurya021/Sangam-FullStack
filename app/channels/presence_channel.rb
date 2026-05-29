class PresenceChannel < ApplicationCable::Channel
  def subscribed
    stream_from "user_presence"

    # Broadcast current user's online status to all subscribers
    # so they immediately see the correct status when they subscribe
    ActionCable.server.broadcast(
      "user_presence",
      {
        type:         'presence_update',
        user_id:      current_user.id,
        online:       true,
        last_seen_at: current_user.last_seen_at&.iso8601
      }
    )
  end

  def unsubscribed
    stop_all_streams
  end
end
