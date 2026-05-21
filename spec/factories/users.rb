FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    
    trait :with_name do
      name { Faker::Name.name }
      email { "#{Faker::Name.first_name.downcase}.#{Faker::Name.last_name.downcase}@example.com" }
    end
    
    trait :confirmed do
      confirmed_at { Time.current }
    end
    
    trait :unconfirmed do
      confirmed_at { nil }
    end
  end
end
