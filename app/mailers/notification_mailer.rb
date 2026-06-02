class NotificationMailer < ApplicationMailer
  # Called when someone likes, comments, replies, sends a friend request, etc.
  def notification_email(notification)
    @notification = notification
    @recipient    = notification.recipient
    @actor        = notification.actor
    @message      = notification.notification_message

    # Build the deep-link URL
    @action_url = begin
      notification.target_url(Rails.application.routes.url_helpers)
    rescue
      root_url
    end

    mail(
      to:      @recipient.email,
      subject: "Sangam — #{@message}"
    )
  end

  # Welcome email after registration
  def welcome_email(user)
    @user = user
    mail(
      to:      @user.email,
      subject: "Welcome to Sangam, #{@user.name}!"
    )
  end

  # Password changed confirmation
  def password_changed_email(user)
    @user = user
    mail(
      to:      @user.email,
      subject: 'Your Sangam password was changed'
    )
  end
end
