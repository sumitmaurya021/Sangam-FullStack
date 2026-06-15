# Sends birthday notifications to user's friends — run daily via recurring task
class BirthdayNotificationJob < ApplicationJob
  queue_as :default

  def perform
    today = Date.today
    # Find all users with birthday today
    birthday_users = User.where(
      'EXTRACT(month FROM birthday) = ? AND EXTRACT(day FROM birthday) = ?',
      today.month, today.day
    )

    birthday_users.each do |birthday_user|
      # Notify all their friends
      birthday_user.all_friends.each do |friend|
        # Skip if already notified today
        next if Notification.where(
          recipient: friend,
          actor: birthday_user,
          notification_type: 'birthday'
        ).where('created_at >= ?', Date.today.beginning_of_day).exists?

        Notification.create!(
          recipient: friend,
          actor: birthday_user,
          notification_type: 'birthday',
          message: "Today is #{birthday_user.name}'s birthday! 🎂"
        )
      end
    end

    Rails.logger.info "BirthdayNotificationJob: processed #{birthday_users.count} birthdays."
  end
end
