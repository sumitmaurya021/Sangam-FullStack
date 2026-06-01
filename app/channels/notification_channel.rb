class NotificationChannel < ApplicationCable::Channel
  def subscribed
    stream_from "notifications_#{current_user.id}"
  end

  def unsubscribed
    stop_all_streams
  end

  # Mark a single notification as read
  def mark_read(data)
    notification = current_user.notifications.find_by(id: data['notification_id'])
    notification&.mark_as_read!
    # Broadcast updated unread count
    broadcast_unread_count
  end

  # Mark all notifications as read
  def mark_all_read
    current_user.notifications.unread.update_all(read_at: Time.current)
    broadcast_unread_count
  end

  private

  def broadcast_unread_count
    count = current_user.notifications.unread.count
    ActionCable.server.broadcast(
      "notifications_#{current_user.id}",
      { type: 'unread_count', count: count }
    )
  end
end
