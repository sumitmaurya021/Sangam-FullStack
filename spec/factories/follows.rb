FactoryBot.define do
  factory :follow do
    association :follower, factory: :user
    # Use a separate user instance to avoid self-follow
    followee { association(:user) }
  end
end
