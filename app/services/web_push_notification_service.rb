# frozen_string_literal: true

class WebPushNotificationService
  class << self
    # Dispatches a push notification to all subscriptions belonging to the user
    def send_to_user(user, title:, body:, icon: nil, badge: nil, path: nil, tag: nil, data: {})
      return false unless user.is_a?(User)
      return false if user.push_subscriptions.empty?

      payload = {
        title: title,
        options: {
          body: body,
          icon: icon.presence || '/icon.svg',
          badge: badge.presence || '/icon.svg',
          tag: tag.presence || "sangam-#{Time.current.to_i}",
          renotify: true,
          vibrate: [100, 50, 100],
          data: (data || {}).merge({
            path: path.presence || '/',
            timestamp: Time.current.iso8601
          })
        }
      }

      dispatched_count = 0

      user.push_subscriptions.find_each do |subscription|
        success = send_payload(subscription, payload)
        dispatched_count += 1 if success
      end

      dispatched_count
    end

    def send_payload(subscription, payload)
      message_json = JSON.generate(payload)

      Webpush.payload_send(
        message: message_json,
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh_key,
        auth: subscription.auth_key,
        vapid: {
          subject: Rails.application.config.vapid_subject,
          public_key: Rails.application.config.vapid_public_key,
          private_key: Rails.application.config.vapid_private_key
        }
      )
      true
    rescue Webpush::ExpiredSubscription, Net::HTTPGone, Net::HTTPNotFound => e
      Rails.logger.info("[WebPush] Subscription expired or removed (#{e.class.name}), cleaning up id=#{subscription.id}")
      subscription.destroy
      false
    rescue => e
      if e.respond_to?(:response) && %w[404 410].include?(e.response.try(:code).to_s)
        Rails.logger.info("[WebPush] Subscription returned #{e.response.code}, cleaning up id=#{subscription.id}")
        subscription.destroy
      else
        Rails.logger.error("[WebPush] Failed to send push to subscription #{subscription.id}: #{e.message}")
      end
      false
    end
  end
end
