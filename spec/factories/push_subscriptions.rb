# frozen_string_literal: true

FactoryBot.define do
  factory :push_subscription do
    association :user
    endpoint { "https://fcm.googleapis.com/fcm/send/#{SecureRandom.hex(16)}" }
    p256dh_key { Base64.urlsafe_encode64(SecureRandom.random_bytes(65), padding: false) }
    auth_key { Base64.urlsafe_encode64(SecureRandom.random_bytes(16), padding: false) }
    user_agent { "Mozilla/5.0 (Windows NT 10.0; Win64; x64)" }
  end
end
