FactoryBot.define do
  factory :story do
    association :user
    story_type { 'text' }
    archived { false }
    expires_at { 24.hours.from_now }
  end

  factory :reel do
    association :user
    caption { Faker::Lorem.sentence }
    likes_count { 0 }
    comments_count { 0 }
    views_count { 0 }
  end

  factory :reel_comment do
    association :user
    association :reel
    body { Faker::Lorem.sentence }
  end

  factory :reel_like do
    association :user
    association :reel
  end

  factory :group do
    association :owner, factory: :user
    name { Faker::Company.name }
    description { Faker::Lorem.paragraph }
    privacy { 'public_group' }
  end

  factory :group_membership do
    association :user
    association :group
    role { 'member' }
    status { 'approved' }
  end

  factory :group_chat do
    association :owner, factory: :user
    name { Faker::Team.name }
  end

  factory :group_chat_member do
    association :user
    association :group_chat
  end

  factory :group_chat_message do
    association :user
    association :group_chat
    content { Faker::Lorem.sentence }
  end

  factory :conversation do
    association :sender, factory: :user
    association :recipient, factory: :user
  end

  factory :message do
    association :conversation
    association :user
    message_type { 'text' }
    body { Faker::Lorem.sentence }
  end

  factory :notification do
    association :recipient, factory: :user
    association :actor, factory: :user
    notification_type { 'like' }
    notifiable { association :post }
  end

  factory :poll do
    association :post
    question { Faker::Lorem.question }
    after(:build) do |poll|
      poll.poll_options << build(:poll_option, poll: poll, body: 'Option 1') if poll.poll_options.empty?
      poll.poll_options << build(:poll_option, poll: poll, body: 'Option 2') if poll.poll_options.size == 1
    end
  end

  factory :poll_option do
    association :poll
    body { Faker::Lorem.word }
  end

  factory :poll_vote do
    association :user
    association :poll_option
  end

  factory :event do
    association :organizer, factory: :user
    title { Faker::Event.name rescue 'Community Meetup' }
    description { Faker::Lorem.paragraph }
    start_time { 1.day.from_now }
    location { Faker::Address.full_address }
  end

  factory :event_response do
    association :user
    association :event
    status { 'going' }
  end

  factory :marketplace_listing do
    association :user
    title { Faker::Commerce.product_name }
    description { Faker::Lorem.paragraph }
    price { 99.99 }
    category { 'Electronics' }
    condition { 'Like New' }
    status { 'active' }
  end

  factory :fundraiser do
    association :user
    title { Faker::Company.bs }
    description { Faker::Lorem.paragraph }
    goal_amount { 1000.00 }
    current_amount { 0.00 }
  end

  factory :bookmark do
    association :user
    association :bookmarkable, factory: :post
  end

  factory :bookmark_collection do
    association :user
    name { Faker::Lorem.word }
  end

  factory :profile_highlight do
    association :user
    title { Faker::Lorem.word }
  end

  factory :close_friend do
    association :user
    association :close_friend, factory: :user
  end

  factory :digital_twin do
    association :user
    personality_prompt { 'Friendly AI Assistant' }
    auto_reply_enabled { true }
    confidence_threshold { 0.85 }
  end

  factory :digital_twin_log do
    association :user
    association :digital_twin
    action { 'auto_reply' }
    prompt_used { 'Hello' }
    response_generated { 'Hi there!' }
    confidence_score { 0.95 }
  end

  factory :synapse_stream do
    association :user
    title { Faker::Lorem.sentence }
    modality { 'multimodal' }
    status { 'completed' }
  end

  factory :ux_mutation_preference do
    association :user
    active_theme { 'dark' }
    font_scale { 'medium' }
    ui_density { 'comfortable' }
  end

  factory :ux_telemetry_event do
    association :user
    event_type { 'click' }
    component_id { 'nav_link' }
  end

  factory :hashtag do
    name { Faker::Lorem.unique.word }
  end

  factory :post_hashtag do
    association :post
    association :hashtag
  end

  factory :post_collaborator do
    association :post
    association :user
    status { 'pending' }
  end

  factory :ai_moderation_log do
    association :user
    content_type { 'Post' }
    content_id { 1 }
    flagged { false }
    action_taken { 'approved' }
  end
end
