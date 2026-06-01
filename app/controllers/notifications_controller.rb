class NotificationsController < ApplicationController
  before_action :authenticate_user!

  # GET /notifications — full notifications page
  def index
    @notifications = current_user.notifications
                                 .includes(:actor)
                                 .recent
                                 .page(params[:page])
                                 .per(20)
    @unread_count = current_user.notifications.unread.count

    respond_to do |format|
      format.html
      format.json do
        render json: {
          notifications: @notifications.map { |n| notification_json(n) },
          unread_count: @unread_count,
          total_count: current_user.notifications.count
        }
      end
    end
  end

  # GET /notifications/dropdown — partial for header dropdown (last 10)
  def dropdown
    @notifications = current_user.notifications
                                 .includes(:actor)
                                 .recent
                                 .limit(10)
    @unread_count = current_user.notifications.unread.count

    render json: {
      notifications: @notifications.map { |n| notification_json(n) },
      unread_count: @unread_count
    }
  end

  # PATCH /notifications/:id/read
  def mark_read
    @notification = current_user.notifications.find(params[:id])
    @notification.mark_as_read!

    render json: {
      success: true,
      unread_count: current_user.notifications.unread.count
    }
  end

  # PATCH /notifications/mark_all_read
  def mark_all_read
    current_user.notifications.unread.update_all(read_at: Time.current)

    render json: {
      success: true,
      unread_count: 0
    }
  end

  # DELETE /notifications/:id
  def destroy
    @notification = current_user.notifications.find(params[:id])
    @notification.destroy

    render json: {
      success: true,
      unread_count: current_user.notifications.unread.count
    }
  end

  private

  def notification_json(notification)
    target_url = begin
      notification.target_url(Rails.application.routes.url_helpers)
    rescue
      posts_path
    end

    # For friend_request, include friendship details for inline accept/decline
    friendship_id = nil
    friendship_accepted = false
    if notification.notification_type == 'friend_request' && notification.notifiable.is_a?(Friendship)
      friendship_id = notification.notifiable.id
      friendship_accepted = notification.notifiable.status == 'accepted'
    end

    {
      id: notification.id,
      notification_type: notification.notification_type,
      message: notification.notification_message,
      icon: notification.notification_icon,
      read: notification.read?,
      created_at: notification.created_at.iso8601,
      time_ago: helpers.time_ago_in_words(notification.created_at),
      target_url: target_url,
      friendship_id: friendship_id,
      friendship_accepted: friendship_accepted,
      actor: {
        id: notification.actor.id,
        name: notification.actor.name,
        avatar: actor_avatar(notification.actor)
      }
    }
  end

  def actor_avatar(actor)
    if actor.avatar.attached?
      rails_blob_path(actor.avatar, only_path: true)
    else
      nil
    end
  rescue
    nil
  end
end
