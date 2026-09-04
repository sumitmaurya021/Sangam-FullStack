# frozen_string_literal: true

class PushSubscriptionsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [:create, :destroy, :test]

  def create
    subscription_params = params.require(:subscription)
    endpoint = subscription_params[:endpoint]
    keys = subscription_params[:keys] || {}

    if endpoint.blank? || keys[:p256dh].blank? || keys[:auth].blank?
      return render json: { error: 'Invalid subscription payload' }, status: :unprocessable_entity
    end

    subscription = current_user.push_subscriptions.find_or_initialize_by(endpoint: endpoint)
    subscription.p256dh_key = keys[:p256dh]
    subscription.auth_key = keys[:auth]
    subscription.user_agent = request.user_agent

    if subscription.save
      render json: {
        status: 'ok',
        id: subscription.id,
        message: 'Subscribed to push notifications successfully'
      }, status: :created
    else
      render json: { error: subscription.errors.full_messages.join(', ') }, status: :unprocessable_entity
    end
  end

  def destroy
    endpoint = params[:endpoint]
    subscription = if endpoint.present?
                     current_user.push_subscriptions.find_by(endpoint: endpoint)
                   elsif params[:id].present?
                     current_user.push_subscriptions.find_by(id: params[:id])
                   end

    if subscription&.destroy
      render json: { status: 'ok', message: 'Unsubscribed from push notifications successfully' }
    else
      render json: { status: 'ok', message: 'Subscription already removed' }
    end
  end

  def test
    if current_user.push_subscriptions.empty?
      return render json: {
        error: 'No active push subscriptions found on your account. Please enable notifications first.'
      }, status: :not_found
    end

    dispatched = WebPushNotificationService.send_to_user(
      current_user,
      title: 'Sangam Notifications Active! 🚀',
      body: 'Web Push is working perfectly! You will receive updates even when your browser tab is closed.',
      icon: '/icon.svg',
      path: root_path,
      tag: "test-push-#{Time.current.to_i}",
      data: { type: 'test' }
    )

    render json: {
      status: 'ok',
      dispatched_count: dispatched,
      message: 'Test notification sent! Check your desktop/phone system notifications.'
    }
  end

  def status
    render json: {
      subscribed: current_user.push_subscriptions.exists?,
      count: current_user.push_subscriptions.count,
      vapid_public_key: Rails.application.config.vapid_public_key
    }
  end
end
