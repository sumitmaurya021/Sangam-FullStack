class PresenceChannel < ApplicationCable::Channel
  def subscribed
    stream_from "user_presence"

    # Send a heartbeat ping to client so it knows to start pinging back
    transmit({ type: 'ping_request' })
  end

  # Client sends periodic heartbeat to confirm they are still active
  def heartbeat
    current_user.update_columns(online: true, last_seen_at: Time.current)
  end

  def unsubscribed
    # Mark offline immediately when this channel unsubscribes
    # (covers tab close, navigation away, etc.)
    current_user.update_columns(online: false, last_seen_at: Time.current)
    ActionCable.server.broadcast(
      "user_presence",
      {
        type:         'presence_update',
        user_id:      current_user.id,
        online:       false,
        last_seen_at: current_user.last_seen_at&.iso8601
      }
    )
    stop_all_streams
  end
end
