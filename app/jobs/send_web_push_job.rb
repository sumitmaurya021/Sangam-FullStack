# frozen_string_literal: true

class SendWebPushJob < ApplicationJob
  queue_as :notifications

  def perform(user_id, payload)
    user = User.find_by(id: user_id)
    return unless user

    symbolized_payload = payload.deep_symbolize_keys
    WebPushNotificationService.send_to_user(
      user,
      title: symbolized_payload[:title],
      body: symbolized_payload[:body],
      icon: symbolized_payload[:icon],
      badge: symbolized_payload[:badge],
      path: symbolized_payload[:path],
      tag: symbolized_payload[:tag],
      data: symbolized_payload[:data] || {}
    )
  end
end
