# Sends reminder notifications for events starting within 24 hours
class EventReminderJob < ApplicationJob
  queue_as :default

  def perform
    # Events starting in next 24 hours that haven't sent reminders
    upcoming = Event.where(
      reminder_sent: false,
      starts_at: Time.current..24.hours.from_now
    )

    upcoming.each do |event|
      # Notify all "going" attendees
      going_user_ids = event.event_responses.where(response: 'going').pluck(:user_id)
      going_user_ids.each do |user_id|
        Notification.create!(
          recipient_id:      user_id,
          actor:             event.organizer,
          notifiable:        event,
          notification_type: 'event_reminder',
          message:           "Reminder: \"#{event.title}\" starts in less than 24 hours!"
        )
      end
      event.update_column(:reminder_sent, true)
    end

    Rails.logger.info "EventReminderJob: sent reminders for #{upcoming.count} events."
  end
end
