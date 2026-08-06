FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    bio { Faker::Lorem.sentence }
    website_url { 'https://example.com' }
    confirmed_at { Time.current }

    trait :super_admin do
      super_admin { true }
    end

    trait :with_2fa do
      otp_enabled { true }
      otp_secret { ROTP::Base32.random }
    end

    trait :ai_bot do
      is_ai { true }
      email { 'ai@sangam.com' }
      name { 'AI Assistant ✨' }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end
  end
end
